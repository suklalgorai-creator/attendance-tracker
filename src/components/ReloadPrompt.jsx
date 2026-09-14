import React from 'react';
import { useRegisterSW } from 'virtual:pwa-register/react';

export default function ReloadPrompt() {
  const {
    needRefresh: [needRefresh, setNeedRefresh],
    updateServiceWorker,
  } = useRegisterSW({
    onRegistered(r) {
      // eslint-disable-next-line prefer-template
      console.log('SW Registered: ' + r);
    },
    onRegisterError(error) {
      console.log('SW registration error', error);
    },
  });

  if (!needRefresh) return null;

  return (
    <div className="pwa-toast">
      <div className="pwa-toast-message">
        <span>A new version of the app is available!</span>
      </div>
      <div className="pwa-toast-buttons">
        <button className="btn-present pwa-update-btn" onClick={() => updateServiceWorker(true)}>
          Update Now
        </button>
        <button className="btn-clear pwa-close-btn" onClick={() => setNeedRefresh(false)}>
          Close
        </button>
      </div>
    </div>
  );
}
