import { CURRENT_SCHEMA_VERSION, migrateUserData, nowIso } from './dataModel.js';

const BACKUP_FORMAT = 'college-attendance-tracker-backup';
const MAX_BACKUP_BYTES = 5 * 1024 * 1024;

export function createBackup(data) {
  return {
    format: BACKUP_FORMAT,
    schemaVersion: CURRENT_SCHEMA_VERSION,
    exportedAt: nowIso(),
    data: migrateUserData(data).data,
  };
}

export function parseBackup(text) {
  if (typeof text !== 'string' || text.length === 0 || text.length > MAX_BACKUP_BYTES) {
    throw new Error('Backup file is empty or exceeds the 5 MB safety limit.');
  }
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new Error('This file is not valid JSON. Existing data was not changed.');
  }
  if (!parsed || parsed.format !== BACKUP_FORMAT || !parsed.data) {
    throw new Error('This is not a College Attendance Tracker backup. Existing data was not changed.');
  }
  if (Number(parsed.schemaVersion) > CURRENT_SCHEMA_VERSION) {
    throw new Error('This backup is from a newer app version and cannot be restored safely.');
  }
  const migration = migrateUserData(parsed.data);
  return {
    data: migration.data,
    summary: {
      subjects: migration.data.subjects.length,
      sessions: Object.values(migration.data.timetable).flat().filter((session) => !session.deletedAt).length,
      attendanceRecords: migration.data.attendanceRecords.filter((record) => !record.deletedAt).length,
      legacyRecords: migration.data.legacyAttendance.filter((record) => !record.deletedAt).length,
      quarantined: migration.quarantineCount,
    },
    warnings: migration.warnings,
  };
}

export function downloadJsonBackup(data) {
  const blob = new Blob([JSON.stringify(createBackup(data), null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = `attendance-backup-${new Date().toISOString().slice(0, 10)}.json`;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
