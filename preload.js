'use strict';

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  loadProfiles: () => ipcRenderer.invoke('profiles:load'),
  saveProfiles: (p) => ipcRenderer.invoke('profiles:save', p),
  loadPrefs:    () => ipcRenderer.invoke('prefs:load'),
  savePrefs:    (p) => ipcRenderer.invoke('prefs:save', p),

  getRunning:   () => ipcRenderer.invoke('running:get'),
  launch:       (prof) => ipcRenderer.invoke('launch', prof),
  close:        (dir) => ipcRenderer.invoke('close', dir),
  openFolder:   (dir) => ipcRenderer.invoke('open-folder', dir),
  whois:        (dir) => ipcRenderer.invoke('whois', dir),
  pickFolder:   () => ipcRenderer.invoke('pick-folder'),
  envPaths:     () => ipcRenderer.invoke('env:paths'),
  exeCheck:     () => ipcRenderer.invoke('exe-check'),
  messageBox:   (opts) => ipcRenderer.invoke('message-box', opts),

  contextMenu:  (items) => ipcRenderer.invoke('context-menu', items),
  onContextClick: (cb) => {
    const handler = (_e, id) => cb(id);
    ipcRenderer.on('context-menu:click', handler);
    return () => ipcRenderer.removeListener('context-menu:click', handler);
  },
  onLaunchError: (cb) => {
    const handler = (_e, payload) => cb(payload);
    ipcRenderer.on('launch-error', handler);
    return () => ipcRenderer.removeListener('launch-error', handler);
  },

  window: {
    minimize: () => ipcRenderer.invoke('window:minimize'),
    close:    () => ipcRenderer.invoke('window:close'),
    toggleMax:() => ipcRenderer.invoke('window:toggle-max'),
  },
});
