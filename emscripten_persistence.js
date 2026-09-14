// Persist fheroes2 user configuration and save games in browser IndexedDB.
// Keep all user-writable fheroes2 files below one IDBFS mount.
Module['preRun'] = Module['preRun'] || [];
Module['preRun'].push(function () {
    const persistentDirectory = '/fheroes2';

    // fheroes2's Linux path code uses HOME/XDG_CONFIG_HOME/XDG_DATA_HOME.
    Object.assign(globalThis.ENV, {
        HOME: persistentDirectory,
        XDG_CONFIG_HOME: persistentDirectory + '/.config',
        XDG_DATA_HOME: persistentDirectory + '/.local/share'
    });

    FS.mkdirTree(persistentDirectory);
    FS.mount(IDBFS, { root: '/', autoPersist: true }, persistentDirectory);

    console.log('fheroes2 persistence: mounting IDBFS at ' + persistentDirectory);

    addRunDependency('fheroes2-idbfs-load');
    FS.syncfs(true, function (error) {
        if (error) {
            console.error('fheroes2 persistence: unable to load IndexedDB:', error);
        } else {
            console.log('fheroes2 persistence: loaded IndexedDB data');
        }
        removeRunDependency('fheroes2-idbfs-load');
    });
});
