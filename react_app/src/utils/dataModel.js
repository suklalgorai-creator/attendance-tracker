import { DEFAULT_CLASS_DAYS, DEFAULT_MIN } from '../constants.js';
import { isDateOnly, parseDateOnly } from './date.js';

export const CURRENT_SCHEMA_VERSION = 2;
export const DAILY_SUBJECT_ID = '__daily__';
export const ATTENDANCE_STATUS = Object.freeze({
  PRESENT: 'PRESENT',
  ABSENT: 'ABSENT',
  UNMARKED: 'UNMARKED',
  CANCELLED: 'CANCELLED',
});

const STATUS_VALUES = new Set(Object.values(ATTENDANCE_STATUS));

export function nowIso() {
  return new Date().toISOString();
}

export function createId(prefix = 'id') {
  const value = globalThis.crypto?.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  return `${prefix}-${value}`;
}

function stableLegacyId(prefix, value) {
  let hash = 5381;
  for (const char of value) hash = ((hash * 33) ^ char.charCodeAt(0)) >>> 0;
  return `${prefix}-${hash.toString(36)}`;
}

function isObject(value) {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function safeString(value, fallback = '') {
  return typeof value === 'string' ? value.trim() : fallback;
}

function validTimestamp(value, fallback) {
  return typeof value === 'string' && !Number.isNaN(Date.parse(value)) ? value : fallback;
}

function integer(value) {
  return Number.isInteger(value) && Number.isFinite(value) ? value : null;
}

function safeSerialized(value) {
  try {
    return JSON.stringify(value).slice(0, 1500);
  } catch {
    return '[unserializable value]';
  }
}

function quarantineItem(kind, value, reason, receivedAt) {
  return {
    id: createId('quarantine'),
    kind,
    reason,
    record: safeSerialized(value),
    receivedAt,
  };
}

function normalizeSubject(value, receivedAt) {
  if (!isObject(value) || !safeString(value.id) || !safeString(value.name)) return null;
  return {
    id: safeString(value.id),
    name: safeString(value.name).slice(0, 120),
    color: safeString(value.color, '#10B981').slice(0, 32),
    active: value.active !== false,
    createdAt: validTimestamp(value.createdAt, receivedAt),
    updatedAt: validTimestamp(value.updatedAt, receivedAt),
    deletedAt: value.deletedAt ? validTimestamp(value.deletedAt, receivedAt) : null,
  };
}

function normalizeSession(value, subjectIds, receivedAt) {
  if (!isObject(value) || !safeString(value.id) || !subjectIds.has(value.subjectId)) return null;
  return {
    id: safeString(value.id),
    subjectId: value.subjectId,
    label: safeString(value.label).slice(0, 120),
    active: value.active !== false,
    createdAt: validTimestamp(value.createdAt, receivedAt),
    updatedAt: validTimestamp(value.updatedAt, receivedAt),
    deletedAt: value.deletedAt ? validTimestamp(value.deletedAt, receivedAt) : null,
  };
}

function normalizeAttendanceRecord(value, subjectIds, receivedAt) {
  if (!isObject(value)) return { error: 'Record must be an object.' };
  if (!safeString(value.id)) return { error: 'Record is missing a stable id.' };
  if (!isDateOnly(value.date)) return { error: 'Record has an invalid date.' };
  const subjectId = safeString(value.subjectId) || DAILY_SUBJECT_ID;
  if (subjectId !== DAILY_SUBJECT_ID && !subjectIds.has(subjectId)) return { error: 'Record references an unknown subject.' };
  if (!safeString(value.sessionId)) return { error: 'Record is missing a session id.' };
  if (!STATUS_VALUES.has(value.status)) return { error: 'Record has an invalid attendance status.' };
  return {
    value: {
      id: safeString(value.id),
      date: value.date,
      subjectId,
      sessionId: safeString(value.sessionId),
      status: value.status,
      createdAt: validTimestamp(value.createdAt, receivedAt),
      updatedAt: validTimestamp(value.updatedAt, receivedAt),
      deletedAt: value.deletedAt ? validTimestamp(value.deletedAt, receivedAt) : null,
      source: value.source === 'manual' ? 'manual' : 'schedule',
    },
  };
}

function normalizeLegacyRecord(value, receivedAt) {
  if (!isObject(value) || !safeString(value.id) || !isDateOnly(value.date)) return null;
  const held = integer(value.held);
  const attended = integer(value.attended);
  if (held === null || attended === null || held < 0 || attended < 0 || attended > held) return null;
  return {
    id: safeString(value.id),
    date: value.date,
    held,
    attended,
    createdAt: validTimestamp(value.createdAt, receivedAt),
    updatedAt: validTimestamp(value.updatedAt, receivedAt),
    deletedAt: value.deletedAt ? validTimestamp(value.deletedAt, receivedAt) : null,
    note: safeString(value.note).slice(0, 240),
  };
}

function uniqueById(values, kind, quarantine, receivedAt) {
  const byId = new Map();
  values.forEach((value) => {
    const existing = byId.get(value.id);
    if (!existing || existing.updatedAt < value.updatedAt) {
      if (existing) quarantine.push(quarantineItem(kind, existing, 'Superseded duplicate id.', receivedAt));
      byId.set(value.id, value);
    } else {
      quarantine.push(quarantineItem(kind, value, 'Duplicate id retained as quarantine.', receivedAt));
    }
  });
  return [...byId.values()];
}

function makeLegacyRecords(records, receivedAt, quarantine) {
  if (!isObject(records)) return [];
  return Object.entries(records).flatMap(([date, record]) => {
    if (!isDateOnly(date) || !isObject(record)) {
      quarantine.push(quarantineItem('legacy-record', { date, record }, 'Invalid legacy daily record.', receivedAt));
      return [];
    }
    const held = integer(record.held);
    const attended = integer(record.attended);
    if (held === null || attended === null || held < 0 || attended < 0 || attended > held) {
      quarantine.push(quarantineItem('legacy-record', { date, record }, 'Invalid legacy attendance totals.', receivedAt));
      return [];
    }
    return [{
      id: `legacy-${date}`,
      date,
      held,
      attended,
      createdAt: receivedAt,
      updatedAt: receivedAt,
      deletedAt: null,
      note: 'Migrated from the v1 daily aggregate. Subject/session detail was not available.',
    }];
  });
}

function migrateLegacyTimetable(timetable, subjects, receivedAt) {
  const subjectByName = new Map(subjects.map((subject) => [subject.name.toLowerCase(), subject]));
  const result = {};
  if (!isObject(timetable)) return result;

  Object.entries(timetable).forEach(([day, values]) => {
    if (!/^[0-6]$/.test(day) || !Array.isArray(values)) return;
    result[day] = values.flatMap((value, index) => {
      if (isObject(value)) return [value];
      const name = safeString(value);
      if (!name) return [];
      let subject = subjectByName.get(name.toLowerCase());
      if (!subject) {
        subject = {
          id: stableLegacyId('legacy-subject', name.toLowerCase()),
          name: name.slice(0, 120),
          color: '#10B981',
          active: true,
          createdAt: receivedAt,
          updatedAt: receivedAt,
          deletedAt: null,
        };
        subjects.push(subject);
        subjectByName.set(subject.name.toLowerCase(), subject);
      }
      return [{
        id: stableLegacyId('legacy-schedule', `${day}:${index}:${subject.id}`),
        subjectId: subject.id,
        label: name.slice(0, 120),
        active: true,
        createdAt: receivedAt,
        updatedAt: receivedAt,
        deletedAt: null,
      }];
    });
  });
  return result;
}

export function createInitialData(overrides = {}) {
  const timestamp = nowIso();
  return {
    schemaVersion: CURRENT_SCHEMA_VERSION,
    programName: '',
    courseName: '',
    startDate: overrides.startDate || '',
    minPercent: DEFAULT_MIN,
    classDays: [...DEFAULT_CLASS_DAYS],
    timetable: {},
    subjects: [],
    attendanceRecords: [],
    legacyAttendance: [],
    quarantine: [],
    notes: [],
    theme: 'dark',
    reminderTime: '18:00',
    pushNotificationsEnabled: false,
    leaderboardOptIn: true,
    fcmToken: null,
    adminRequestedPush: false,
    lastNotified: null,
    settingsUpdatedAt: timestamp,
    updatedAt: timestamp,
    ...overrides,
  };
}

/**
 * Migrates persisted v1/v2 data into a validated v2 model. Invalid values are
 * retained as quarantined diagnostics instead of being silently discarded.
 */
export function migrateUserData(rawData) {
  const raw = isObject(rawData) ? rawData : {};
  // V1 did not have per-entity timestamps. A fixed migration timestamp keeps
  // the same historical record deterministic on every device.
  const receivedAt = raw.schemaVersion === CURRENT_SCHEMA_VERSION
    ? nowIso()
    : validTimestamp(raw.updatedAt, '2000-01-01T00:00:00.000Z');
  const quarantine = Array.isArray(raw.quarantine) ? raw.quarantine.filter(isObject).slice(-100) : [];
  const warnings = [];
  const sourceSubjects = Array.isArray(raw.subjects) ? raw.subjects : [];
  const subjects = uniqueById(
    sourceSubjects.flatMap((value) => {
      const normalized = normalizeSubject(value, receivedAt);
      if (!normalized) {
        quarantine.push(quarantineItem('subject', value, 'Invalid subject.', receivedAt));
        return [];
      }
      return [normalized];
    }),
    'subject', quarantine, receivedAt,
  );

  const timetableSource = raw.timetable || {};
  const legacyTimetable = raw.schemaVersion === CURRENT_SCHEMA_VERSION
    ? timetableSource
    : migrateLegacyTimetable(timetableSource, subjects, receivedAt);
  const subjectIds = new Set(subjects.map((subject) => subject.id));
  const timetable = {};
  if (isObject(legacyTimetable)) {
    Object.entries(legacyTimetable).forEach(([day, values]) => {
      if (!/^[0-6]$/.test(day) || !Array.isArray(values)) return;
      const sessions = values.flatMap((value) => {
        const normalized = normalizeSession(value, subjectIds, receivedAt);
        if (!normalized) {
          quarantine.push(quarantineItem('schedule-session', value, 'Invalid timetable session.', receivedAt));
          return [];
        }
        return [normalized];
      });
      timetable[day] = uniqueById(sessions, 'schedule-session', quarantine, receivedAt);
    });
  }

  const rawRecords = Array.isArray(raw.attendanceRecords) ? raw.attendanceRecords : [];
  const attendanceRecords = uniqueById(rawRecords.flatMap((value) => {
    const normalized = normalizeAttendanceRecord(value, subjectIds, receivedAt);
    if (normalized.error) {
      quarantine.push(quarantineItem('attendance-record', value, normalized.error, receivedAt));
      return [];
    }
    return [normalized.value];
  }), 'attendance-record', quarantine, receivedAt);

  const sourceLegacy = Array.isArray(raw.legacyAttendance)
    ? raw.legacyAttendance
    : makeLegacyRecords(raw.records, receivedAt, quarantine);
  const legacyAttendance = uniqueById(sourceLegacy.flatMap((value) => {
    const normalized = normalizeLegacyRecord(value, receivedAt);
    if (!normalized) {
      quarantine.push(quarantineItem('legacy-record', value, 'Invalid legacy aggregate.', receivedAt));
      return [];
    }
    return [normalized];
  }), 'legacy-record', quarantine, receivedAt);

  const minPercent = Number(raw.minPercent);
  const normalizedMin = Number.isFinite(minPercent) && minPercent > 0 && minPercent <= 100 ? minPercent : DEFAULT_MIN;
  if (normalizedMin !== minPercent && raw.minPercent !== undefined) warnings.push('Invalid attendance threshold was reset to the default.');
  const classDays = Array.isArray(raw.classDays)
    ? [...new Set(raw.classDays.filter((day) => Number.isInteger(day) && day >= 0 && day <= 6))].sort()
    : [...DEFAULT_CLASS_DAYS];

  const data = createInitialData({
    programName: safeString(raw.programName).slice(0, 120),
    courseName: safeString(raw.courseName).slice(0, 120),
    name: safeString(raw.name).slice(0, 120),
    startDate: isDateOnly(raw.startDate) ? raw.startDate : '',
    minPercent: normalizedMin,
    classDays: classDays.length ? classDays : [...DEFAULT_CLASS_DAYS],
    timetable,
    subjects,
    attendanceRecords,
    legacyAttendance,
    quarantine: quarantine.slice(-100),
    notes: Array.isArray(raw.notes) ? raw.notes.filter(isObject).slice(-500) : [],
    theme: raw.theme === 'light' ? 'light' : 'dark',
    reminderTime: /^\d{2}:\d{2}$/.test(raw.reminderTime || '') ? raw.reminderTime : '18:00',
    pushNotificationsEnabled: raw.pushNotificationsEnabled === true,
    leaderboardOptIn: true,
    fcmToken: typeof raw.fcmToken === 'string' ? raw.fcmToken : null,
    adminRequestedPush: raw.adminRequestedPush === true,
    lastNotified: isDateOnly(raw.lastNotified) ? raw.lastNotified : null,
    settingsUpdatedAt: validTimestamp(raw.settingsUpdatedAt, receivedAt),
    updatedAt: validTimestamp(raw.updatedAt, receivedAt),
  });

  const migrated = raw.schemaVersion !== CURRENT_SCHEMA_VERSION || Boolean(raw.records);
  if (migrated) warnings.unshift('Your existing daily totals were preserved as legacy history. They cannot be split by subject because v1 did not store that information.');
  return { data, warnings, migrated, quarantineCount: data.quarantine.length };
}

export function getSessionsForDate(timetable, dateStr) {
  const date = parseDateOnly(dateStr);
  if (!date) return [];
  return Array.isArray(timetable?.[date.getDay()]) ? timetable[date.getDay()].filter((session) => session.active !== false && !session.deletedAt) : [];
}

export function isValidAttendanceRecord(record, subjects) {
  const subjectIds = new Set((subjects || []).map((subject) => subject.id));
  return Boolean(normalizeAttendanceRecord(record, subjectIds, nowIso()).value);
}
