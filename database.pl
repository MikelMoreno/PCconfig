% Base de datos
cpu('m1', perf(['light', 'medium']), os(['linux', 'macos']), plat('none'), gputype('integrated'), tdp()).
cpu('ryzen 5 5800x', perf(['medium', 'high']), os(['windows', 'linux']), plat('am4'), gputype('discrete'), tdp()).

gpu('m1', gputype('integrated')).
gpu('rtx 3060', gputype('discrete')).