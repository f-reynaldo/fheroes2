// Persist fheroes2 user configuration and save games in browser IndexedDB.
// Keep all user-writable fheroes2 files below one IDBFS mount.
Module['preRun'] = Module['preRun'] || [];
Module['preRun'].push(function () {
    const persistentDirectory = '/fheroes2';

    // Emscripten's ENV object is not necessarily exposed until runtime setup.
    // Initialize it here so the Linux getenv() implementation sees these values.
    globalThis.ENV = globalThis.ENV || {};
    Object.assign(globalThis.ENV, {
        HOME: persistentDirectory,
        XDG_CONFIG_HOME: persistentDirectory + '/.config',
        XDG_DATA_HOME: persistentDirectory + '/.local/share'
    });

    FS.mkdirTree(persistentDirectory);
    FS.mount(IDBFS, { root: '/' }, persistentDirectory);

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

    // Flush native filesystem changes to IndexedDB regularly. This is more
    // robust than relying solely on autoPersist, especially for applications
    // that perform many writes in a short period of time.
    const syncPersistentFilesystem = function () {
        FS.syncfs(false, function (error) {
            if (error) {
                console.error('fheroes2 persistence: unable to save IndexedDB data:', error);
            }
        });
    };

    setInterval(syncPersistentFilesystem, 1000);
});
