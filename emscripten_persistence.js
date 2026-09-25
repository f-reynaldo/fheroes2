// Persist fheroes2 user configuration and save games in browser IndexedDB.
// Mount the Emscripten default HOME directly so fheroes2's existing Linux
// config/data path logic stays inside IDBFS without requiring ENV overrides.
Module['preRun'] = Module['preRun'] || [];
Module['preRun'].push(function () {
    const persistentDirectory = '/home/web_user';

    FS.mkdirTree(persistentDirectory);
    FS.mount(IDBFS, { root: '/' }, persistentDirectory);

    console.log('fheroes2 persistence: mounting IDBFS at ' + persistentDirectory);

    addRunDependency('fheroes2-idbfs-load');
    FS.syncfs(true, function (error) {
        if (error) {
            console.error('fheroes2 persistence: unable to load IndexedDB:', error);
        } else {
            console.log('fheroes2 persistence: loaded IndexedDB data');
            try {
                console.log(
                    'fheroes2 config:',
                    FS.readFile('/home/web_user/.fheroes2/fheroes2.cfg', { encoding: 'utf8' })
                );
            } catch (configError) {
                console.log('fheroes2 config not found yet:', configError);
            }
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
