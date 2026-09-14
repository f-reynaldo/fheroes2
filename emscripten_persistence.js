// Persist fheroes2 user configuration and save games in browser IndexedDB.
// IDBFS is resolved from the Emscripten filesystem object so Closure can
// correctly compile this pre-js file.
Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
    const persistentDirectory = '/home/web_user';
    const idbfs = FS.filesystems.IDBFS;

    FS.mkdirTree(persistentDirectory);
    FS.mount(idbfs, {}, persistentDirectory);

    addRunDependency('fheroes2-idbfs-load');
    FS.syncfs(true, function (error) {
        if (error) {
            console.error('Unable to load persistent fheroes2 data:', error);
        } else {
            console.log('Loaded persistent fheroes2 data from IndexedDB');
        }
        removeRunDependency('fheroes2-idbfs-load');
    });

    let syncing = false;
    const sync = function () {
        if (syncing) {
            return;
        }

        syncing = true;
        FS.syncfs(false, function (error) {
            syncing = false;
            if (error) {
                console.error('Unable to save persistent fheroes2 data:', error);
            }
        });
    };

    setInterval(sync, 2000);
    window.addEventListener('pagehide', sync);
    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'hidden') {
            sync();
        }
    });
});
