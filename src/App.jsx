import React from 'react';
import { AppProvider } from './context/AppContext';
import { BrowserRouter } from 'react-router-dom';
import AppLayout from './layouts/AppLayout';
import ReloadPrompt from './components/ReloadPrompt';
import './styles/global.css';
import './styles/layout.css';
import './styles/components.css';

export default function App() {
  return (
    <BrowserRouter>
      <AppProvider>
        <AppLayout />
        <ReloadPrompt />
      </AppProvider>
    </BrowserRouter>
  );
}
