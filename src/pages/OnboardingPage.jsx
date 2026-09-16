import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import DayPicker from '../components/DayPicker';
import { DEFAULT_MIN, DEFAULT_CLASS_DAYS } from '../constants';
import { todayStr } from '../utils/date';

export default function OnboardingPage() {
  const { persist, toTitleCase, globalSettings } = useApp();

  const [formProgram, setFormProgram] = useState('');
  const [formCourse, setFormCourse] = useState('');
  const [formStart, setFormStart] = useState(todayStr());
  const [formMin, setFormMin] = useState(DEFAULT_MIN);
  const [formClassDays, setFormClassDays] = useState(DEFAULT_CLASS_DAYS);

  const defaultPrograms = ["B.Tech CSE", "B.Tech IT", "B.Tech ECE", "B.Tech Mechanical", "B.Tech Civil", "BCA", "MCA", "BBA", "MBA", "B.Sc", "B.Com", "BA"];
  const defaultSemesters = ["Semester 1", "Semester 2", "Semester 3", "Semester 4", "Semester 5", "Semester 6", "Semester 7", "Semester 8"];
  
  const programOptions = globalSettings?.programs?.length > 0 ? globalSettings.programs : defaultPrograms;
  const semesterOptions = globalSettings?.semesters?.length > 0 ? globalSettings.semesters : defaultSemesters;

  const handleOnboard = () => {
    const next = {
      programName: formProgram.trim(),
      courseName: formCourse.trim(),
      startDate: formStart,
      minPercent: Math.max(1, Math.min(100, Number(formMin) || DEFAULT_MIN)),
      classDays: formClassDays.length ? formClassDays : DEFAULT_CLASS_DAYS,
      records: {},
      bestPercent: 0,
    };
    persist(next);
  };

  return (
    <div className="onboard">
      <h1>Set up your register</h1>
      <p className="onboard-sub">A daily attendance tracker that shows exactly how safe — or how behind — you are.</p>
      <label className="field">
        <span>Degree / Program name (optional)</span>
        <input
          list="program-options"
          value={formProgram}
          onChange={(e) => setFormProgram(e.target.value)}
          onBlur={(e) => setFormProgram(toTitleCase(e.target.value))}
          placeholder="e.g. B.Tech CSE"
        />
        <datalist id="program-options">
          {programOptions.map(p => <option key={p} value={p} />)}
        </datalist>
      </label>
      <label className="field">
        <span>Semester name (optional)</span>
        <input
          list="semester-options"
          value={formCourse}
          onChange={(e) => setFormCourse(e.target.value)}
          onBlur={(e) => setFormCourse(toTitleCase(e.target.value))}
          placeholder="e.g. Semester 3"
        />
        <datalist id="semester-options">
          {semesterOptions.map(s => <option key={s} value={s} />)}
        </datalist>
      </label>
      <label className="field">
        <span>Classes started on</span>
        <input type="date" value={formStart} onChange={(e) => setFormStart(e.target.value)} max={todayStr()} />
      </label>
      <label className="field">
        <span>Minimum attendance required</span>
        <div className="min-row">
          <input type="number" min="1" max="100" value={formMin} onChange={(e) => setFormMin(e.target.value)} />
          <span>%</span>
        </div>
      </label>
      <label className="field">
        <span>Which days do you have class?</span>
        <DayPicker value={formClassDays} onChange={setFormClassDays} />
      </label>
      <button className="btn-present btn-wide" onClick={handleOnboard}>Start tracking</button>
    </div>
  );
}
