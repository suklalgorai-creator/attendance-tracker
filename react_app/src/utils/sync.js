import { migrateUserData } from './dataModel.js';

function timestampOf(value) {
  const timestamp = Date.parse(value?.updatedAt || value?.deletedAt || '');
  return Number.isFinite(timestamp) ? timestamp : 0;
}

function stableValue(value) {
  if (Array.isArray(value)) return `[${value.map(stableValue).sort().join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableValue(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function mergeEntities(local = [], cloud = []) {
  const merged = new Map();
  [...cloud, ...local].forEach((entity) => {
    if (!entity?.id) return;
    const current = merged.get(entity.id);
    if (!current) {
      merged.set(entity.id, entity);
      return;
    }
    const incomingTime = timestampOf(entity);
    const currentTime = timestampOf(current);
    if (incomingTime > currentTime || (incomingTime === currentTime && stableValue(entity) > stableValue(current))) {
      merged.set(entity.id, entity);
    }
  });
  return [...merged.values()];
}

/** Local and cloud are merged entity-by-entity; tombstones are retained. */
export function mergeUserData(localRaw, cloudRaw) {
  const local = migrateUserData(localRaw).data;
  const cloud = migrateUserData(cloudRaw).data;
  const settings = timestampOf(local) >= timestampOf(cloud) ? local : cloud;
  const merged = {
    ...settings,
    subjects: mergeEntities(local.subjects, cloud.subjects),
    attendanceRecords: mergeEntities(local.attendanceRecords, cloud.attendanceRecords),
    legacyAttendance: mergeEntities(local.legacyAttendance, cloud.legacyAttendance),
    quarantine: mergeEntities(local.quarantine, cloud.quarantine).slice(-100),
    notes: mergeEntities(local.notes, cloud.notes),
  };
  const days = new Set([...Object.keys(local.timetable || {}), ...Object.keys(cloud.timetable || {})]);
  merged.timetable = {};
  days.forEach((day) => {
    merged.timetable[day] = mergeEntities(local.timetable?.[day], cloud.timetable?.[day]);
  });
  return migrateUserData(merged).data;
}
