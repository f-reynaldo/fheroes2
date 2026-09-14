// Persist fheroes2 user configuration and save games in browser IndexedDB.
Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
    const persistentDirectory = '/home/web_user';

    FS.mkdirTree(persistentDirectory);
    FS.mount(IDBFS, {}, persistentDirectory);

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
    window.addEventListener('beforeunload', sync);
    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'hidden') {
            sync();
        }
    });
});
