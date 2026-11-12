-- Langues : français, anglais, espagnol, portugais, italien, allemand.
-- Choix "auto" = langue de la console (muOS), sinon anglais.
local I = { lang = "en", choice = "auto" }

I.choices = {
  { id = "auto" },
  { id = "fr", label = "Français" },
  { id = "en", label = "English" },
  { id = "es", label = "Español" },
  { id = "pt", label = "Português" },
  { id = "it", label = "Italiano" },
  { id = "de", label = "Deutsch" },
}

local S = {}

S.fr = {
  music = "Musique",
  albums_1 = "%d album", albums = "%d albums",
  tracks_1 = "%d morceau", tracks = "%d morceaux",
  scanning = "Recherche de la musique",
  found = "%d morceaux trouvés",
  empty_title = "Aucune musique trouvée",
  empty_hint = "Ajoute des albums dans le dossier :",
  empty_hint2 = "Puis appuie sur X pour relancer la recherche.",
  still_scanning = "Recherche en cours… %d",
  all_title = "Tout mélanger",
  all_sub = "Toute ta musique en aléatoire",
  various = "Artistes variés",
  play_album = "Écouter l'album",
  shuffle_hint = "X  aléatoire",
  nothing_playing = "Aucune lecture en cours",
  now_playing = "En lecture",
  track_of = "Morceau %d sur %d",
  loading = "chargement…",
  settings = "Réglages",
  theme = "Thème", dark = "Sombre", light = "Clair",
  accent = "Couleur principale",
  c_bleu = "Bleu", c_corail = "Corail", c_jaune = "Jaune", c_menthe = "Menthe",
  c_violet = "Violet", c_rose = "Rose", c_album = "Pochette",
  album_note = "(couleur de chaque album)", custom = "Personnalisée",
  language = "Langue", auto = "Automatique (console)",
  h_choose = "Choisir", h_open = "Ouvrir", h_list = "Liste", h_grid = "Grille",
  h_listen = "Écouter", h_shuffle = "Mélanger", h_back = "Retour",
  h_prev = "Précédent", h_next = "Suivant", h_seek = "Avancer", h_volume = "Volume",
  h_vol_down = "Moins fort", h_vol_up = "Plus fort", h_change = "Changer",
  favorites = "Favoris", h_fav = "Favori", h_random = "Aléatoire",
  fav_added = "Ajouté aux favoris", fav_removed = "Retiré des favoris",
  fav_empty = "Aucun favori pour l'instant", fav_empty_hint = "Appuie sur Y sur un morceau pour l'ajouter ici.",
  view = "Affichage", library = "Bibliothèque", rescan = "Rechercher la musique",
  by_label = "Afficher par", by_albums = "Albums", by_artists = "Artistes",
  artists_1 = "%d artiste", artists = "%d artistes",
  no_album = "Sans album", unknown_artist = "Artiste inconnu",
  -- Aide
  help = "Aide et raccourcis", help_sub = "Tout ce que tu peux faire, et les boutons",
  h_scroll = "Défiler", key_any = "Un bouton",
  hs_features = "Ce que tu peux faire",
  hf_1 = "Écouter ta musique album par album, avec les pochettes.",
  hf_2 = "La musique est cherchée dans le dossier MUSIC des cartes SD1 et SD2.",
  hf_3 = "Le dossier Favoris (étoile jaune), toujours en premier, regroupe tes morceaux favoris. Les albums favoris passent en tête de liste.",
  hf_4 = "Lire toute ta musique en aléatoire, ou un seul album.",
  hf_5 = "Répéter tout ou un seul morceau, reculer ou avancer dans le morceau.",
  hf_6 = "Éteindre l'écran pendant que la musique continue.",
  hf_7 = "Dans les Réglages : thème sombre ou clair, couleur, langue, grille ou liste, par albums ou par artistes, nouvelle recherche de la musique.",
  hs_everywhere = "Partout", hs_albums = "Liste des albums", hs_album = "Dans un album",
  hs_now = "Écran de lecture", hs_screen = "Écran éteint",
  k_prevnext = "Morceau précédent / suivant",
  k_shuffle_all = "Toute la musique en aléatoire",
  k_volume = "Volume moins fort / plus fort",
  k_screen_off = "Éteindre l'écran (la musique continue)",
  k_quit = "Quitter l'appli",
  k_move = "Se déplacer", k_open = "Ouvrir", k_fav_album = "Album favori",
  k_now = "Écran de lecture", k_settings = "Réglages",
  k_play = "Écouter l'album ou le morceau choisi",
  k_shuffle_album = "Album en aléatoire",
  k_fav_track = "Morceau favori (sur « Écouter l'album » : album favori)",
  k_back = "Retour", k_pause = "Lecture / pause", k_shuffle_toggle = "Aléatoire oui / non",
  k_fav_now = "Morceau favori", k_repeat = "Répétition : non, tout, un seul morceau",
  k_seek = "Reculer / avancer de 10 secondes",
  k_wake = "Rallumer l'écran (L1, R1, L2 et R2 marchent sans le rallumer)",
  hf_screen = "L'écran s'éteint tout seul après 60 secondes sans bouton pendant la lecture (réglable dans sori.cfg).",
  hf_power = "N'utilise pas le bouton Power : il met la console en veille et coupe la musique.",
}

S.en = {
  music = "Music",
  albums_1 = "%d album", albums = "%d albums",
  tracks_1 = "%d track", tracks = "%d tracks",
  scanning = "Searching for music",
  found = "%d tracks found",
  empty_title = "No music found",
  empty_hint = "Add albums to this folder:",
  empty_hint2 = "Then press X to search again.",
  still_scanning = "Still searching… %d",
  all_title = "Shuffle all",
  all_sub = "All your music, shuffled",
  various = "Various artists",
  play_album = "Play album",
  shuffle_hint = "X  shuffle",
  nothing_playing = "Nothing playing",
  now_playing = "Now playing",
  track_of = "Track %d of %d",
  loading = "loading…",
  settings = "Settings",
  theme = "Theme", dark = "Dark", light = "Light",
  accent = "Accent colour",
  c_bleu = "Blue", c_corail = "Coral", c_jaune = "Yellow", c_menthe = "Mint",
  c_violet = "Purple", c_rose = "Pink", c_album = "Cover",
  album_note = "(each album's colour)", custom = "Custom",
  language = "Language", auto = "Automatic (console)",
  h_choose = "Select", h_open = "Open", h_list = "List", h_grid = "Grid",
  h_listen = "Play", h_shuffle = "Shuffle", h_back = "Back",
  h_prev = "Previous", h_next = "Next", h_seek = "Seek", h_volume = "Volume",
  h_vol_down = "Quieter", h_vol_up = "Louder", h_change = "Change",
  favorites = "Favorites", h_fav = "Favorite", h_random = "Shuffle",
  fav_added = "Added to favorites", fav_removed = "Removed from favorites",
  fav_empty = "No favorites yet", fav_empty_hint = "Press Y on a track to add it here.",
  view = "View", library = "Library", rescan = "Scan for music",
  by_label = "Browse by", by_albums = "Albums", by_artists = "Artists",
  artists_1 = "%d artist", artists = "%d artists",
  no_album = "No album", unknown_artist = "Unknown artist",
  -- Help
  help = "Help and shortcuts", help_sub = "Everything you can do, and the buttons",
  h_scroll = "Scroll", key_any = "Any button",
  hs_features = "What you can do",
  hf_1 = "Listen to your music album by album, with cover art.",
  hf_2 = "Music is searched for in the MUSIC folder of the SD1 and SD2 cards.",
  hf_3 = "The Favorites folder (yellow star), always first, gathers your favorite tracks. Favorite albums move to the top of the list.",
  hf_4 = "Play all your music on shuffle, or a single album.",
  hf_5 = "Repeat everything or a single track, skip back or forward within a track.",
  hf_6 = "Turn the screen off while the music keeps playing.",
  hf_7 = "In Settings: dark or light theme, colour, language, grid or list, by albums or by artists, new music scan.",
  hs_everywhere = "Everywhere", hs_albums = "Album list", hs_album = "Inside an album",
  hs_now = "Now playing", hs_screen = "Screen off",
  k_prevnext = "Previous / next track",
  k_shuffle_all = "Shuffle all your music",
  k_volume = "Volume down / up",
  k_screen_off = "Turn the screen off (music keeps playing)",
  k_quit = "Quit the app",
  k_move = "Move", k_open = "Open", k_fav_album = "Favorite album",
  k_now = "Now playing screen", k_settings = "Settings",
  k_play = "Play the album or the selected track",
  k_shuffle_album = "Shuffle the album",
  k_fav_track = "Favorite track (on “Play album”: favorite album)",
  k_back = "Back", k_pause = "Play / pause", k_shuffle_toggle = "Shuffle on / off",
  k_fav_now = "Favorite track", k_repeat = "Repeat: off, all, one track",
  k_seek = "Back / forward 10 seconds",
  k_wake = "Turn the screen back on (L1, R1, L2 and R2 work without waking it)",
  hf_screen = "The screen turns off by itself after 60 seconds without a button press while playing (set in sori.cfg).",
  hf_power = "Don't use the Power button: it puts the console to sleep and stops the music.",
}

S.es = {
  music = "Música",
  albums_1 = "%d álbum", albums = "%d álbumes",
  tracks_1 = "%d canción", tracks = "%d canciones",
  scanning = "Buscando música",
  found = "%d canciones encontradas",
  empty_title = "No se encontró música",
  empty_hint = "Añade álbumes a la carpeta:",
  empty_hint2 = "Luego pulsa X para buscar de nuevo.",
  still_scanning = "Buscando todavía… %d",
  all_title = "Mezclar todo",
  all_sub = "Toda tu música en aleatorio",
  various = "Varios artistas",
  play_album = "Escuchar el álbum",
  shuffle_hint = "X  aleatorio",
  nothing_playing = "Nada en reproducción",
  now_playing = "Reproduciendo",
  track_of = "Canción %d de %d",
  loading = "cargando…",
  settings = "Ajustes",
  theme = "Tema", dark = "Oscuro", light = "Claro",
  accent = "Color principal",
  c_bleu = "Azul", c_corail = "Coral", c_jaune = "Amarillo", c_menthe = "Menta",
  c_violet = "Violeta", c_rose = "Rosa", c_album = "Portada",
  album_note = "(color de cada álbum)", custom = "Personalizado",
  language = "Idioma", auto = "Automático (consola)",
  h_choose = "Elegir", h_open = "Abrir", h_list = "Lista", h_grid = "Cuadrícula",
  h_listen = "Escuchar", h_shuffle = "Mezclar", h_back = "Volver",
  h_prev = "Anterior", h_next = "Siguiente", h_seek = "Avanzar", h_volume = "Volumen",
  h_vol_down = "Bajar", h_vol_up = "Subir", h_change = "Cambiar",
  favorites = "Favoritos", h_fav = "Favorito", h_random = "Aleatorio",
  fav_added = "Añadido a favoritos", fav_removed = "Quitado de favoritos",
  fav_empty = "Aún no hay favoritos", fav_empty_hint = "Pulsa Y en una canción para añadirla aquí.",
  view = "Vista", library = "Biblioteca", rescan = "Buscar música",
  by_label = "Ver por", by_albums = "Álbumes", by_artists = "Artistas",
  artists_1 = "%d artista", artists = "%d artistas",
  no_album = "Sin álbum", unknown_artist = "Artista desconocido",
  -- Ayuda
  help = "Ayuda y atajos", help_sub = "Todo lo que puedes hacer, y los botones",
  h_scroll = "Desplazar", key_any = "Un botón",
  hs_features = "Lo que puedes hacer",
  hf_1 = "Escuchar tu música álbum por álbum, con las portadas.",
  hf_2 = "La música se busca en la carpeta MUSIC de las tarjetas SD1 y SD2.",
  hf_3 = "La carpeta Favoritos (estrella amarilla), siempre la primera, reúne tus canciones favoritas. Los álbumes favoritos pasan al principio de la lista.",
  hf_4 = "Reproducir toda tu música en aleatorio, o un solo álbum.",
  hf_5 = "Repetir todo o una sola canción, retroceder o avanzar dentro de la canción.",
  hf_6 = "Apagar la pantalla mientras la música sigue sonando.",
  hf_7 = "En Ajustes: tema oscuro o claro, color, idioma, cuadrícula o lista, por álbumes o por artistas, nueva búsqueda de música.",
  hs_everywhere = "En todas partes", hs_albums = "Lista de álbumes", hs_album = "Dentro de un álbum",
  hs_now = "Reproducción", hs_screen = "Pantalla apagada",
  k_prevnext = "Canción anterior / siguiente",
  k_shuffle_all = "Toda la música en aleatorio",
  k_volume = "Bajar / subir el volumen",
  k_screen_off = "Apagar la pantalla (la música sigue)",
  k_quit = "Salir de la app",
  k_move = "Moverse", k_open = "Abrir", k_fav_album = "Álbum favorito",
  k_now = "Pantalla de reproducción", k_settings = "Ajustes",
  k_play = "Escuchar el álbum o la canción elegida",
  k_shuffle_album = "Álbum en aleatorio",
  k_fav_track = "Canción favorita (en «Escuchar el álbum»: álbum favorito)",
  k_back = "Volver", k_pause = "Reproducir / pausa", k_shuffle_toggle = "Aleatorio sí / no",
  k_fav_now = "Canción favorita", k_repeat = "Repetir: no, todo, una canción",
  k_seek = "Retroceder / avanzar 10 segundos",
  k_wake = "Encender la pantalla (L1, R1, L2 y R2 funcionan sin encenderla)",
  hf_screen = "La pantalla se apaga sola tras 60 segundos sin pulsar botones durante la reproducción (ajustable en sori.cfg).",
  hf_power = "No uses el botón Power: pone la consola en reposo y detiene la música.",
}

S.pt = {
  music = "Música",
  albums_1 = "%d álbum", albums = "%d álbuns",
  tracks_1 = "%d faixa", tracks = "%d faixas",
  scanning = "Procurando música",
  found = "%d faixas encontradas",
  empty_title = "Nenhuma música encontrada",
  empty_hint = "Adicione álbuns na pasta:",
  empty_hint2 = "Depois pressione X para procurar novamente.",
  still_scanning = "Ainda procurando… %d",
  all_title = "Misturar tudo",
  all_sub = "Todas as suas músicas em ordem aleatória",
  various = "Vários artistas",
  play_album = "Ouvir o álbum",
  shuffle_hint = "X  aleatório",
  nothing_playing = "Nada tocando",
  now_playing = "Tocando agora",
  track_of = "Faixa %d de %d",
  loading = "carregando…",
  settings = "Ajustes",
  theme = "Tema", dark = "Escuro", light = "Claro",
  accent = "Cor principal",
  c_bleu = "Azul", c_corail = "Coral", c_jaune = "Amarelo", c_menthe = "Menta",
  c_violet = "Roxo", c_rose = "Rosa", c_album = "Capa",
  album_note = "(cor de cada álbum)", custom = "Personalizada",
  language = "Idioma", auto = "Automático (console)",
  h_choose = "Escolher", h_open = "Abrir", h_list = "Lista", h_grid = "Grade",
  h_listen = "Ouvir", h_shuffle = "Misturar", h_back = "Voltar",
  h_prev = "Anterior", h_next = "Próxima", h_seek = "Avançar", h_volume = "Volume",
  h_vol_down = "Mais baixo", h_vol_up = "Mais alto", h_change = "Mudar",
  favorites = "Favoritos", h_fav = "Favorito", h_random = "Aleatório",
  fav_added = "Adicionado aos favoritos", fav_removed = "Removido dos favoritos",
  fav_empty = "Ainda não há favoritos", fav_empty_hint = "Pressione Y numa música para adicioná-la aqui.",
  view = "Exibição", library = "Biblioteca", rescan = "Procurar música",
  by_label = "Ver por", by_albums = "Álbuns", by_artists = "Artistas",
  artists_1 = "%d artista", artists = "%d artistas",
  no_album = "Sem álbum", unknown_artist = "Artista desconhecido",
  -- Ajuda
  help = "Ajuda e atalhos", help_sub = "Tudo o que você pode fazer, e os botões",
  h_scroll = "Rolar", key_any = "Um botão",
  hs_features = "O que você pode fazer",
  hf_1 = "Ouvir sua música álbum por álbum, com as capas.",
  hf_2 = "A música é procurada na pasta MUSIC dos cartões SD1 e SD2.",
  hf_3 = "A pasta Favoritos (estrela amarela), sempre a primeira, reúne suas músicas favoritas. Os álbuns favoritos vão para o topo da lista.",
  hf_4 = "Tocar toda a sua música em ordem aleatória, ou um único álbum.",
  hf_5 = "Repetir tudo ou uma única música, voltar ou avançar dentro da música.",
  hf_6 = "Desligar a tela enquanto a música continua tocando.",
  hf_7 = "Nas Configurações: tema escuro ou claro, cor, idioma, grade ou lista, por álbuns ou por artistas, nova busca de música.",
  hs_everywhere = "Em todo lugar", hs_albums = "Lista de álbuns", hs_album = "Dentro de um álbum",
  hs_now = "Tocando agora", hs_screen = "Tela desligada",
  k_prevnext = "Música anterior / seguinte",
  k_shuffle_all = "Toda a música em aleatório",
  k_volume = "Diminuir / aumentar o volume",
  k_screen_off = "Desligar a tela (a música continua)",
  k_quit = "Sair do app",
  k_move = "Mover", k_open = "Abrir", k_fav_album = "Álbum favorito",
  k_now = "Tela de reprodução", k_settings = "Configurações",
  k_play = "Ouvir o álbum ou a música escolhida",
  k_shuffle_album = "Álbum em aleatório",
  k_fav_track = "Música favorita (em “Ouvir o álbum”: álbum favorito)",
  k_back = "Voltar", k_pause = "Tocar / pausar", k_shuffle_toggle = "Aleatório sim / não",
  k_fav_now = "Música favorita", k_repeat = "Repetir: não, tudo, uma música",
  k_seek = "Voltar / avançar 10 segundos",
  k_wake = "Religar a tela (L1, R1, L2 e R2 funcionam sem religá-la)",
  hf_screen = "A tela desliga sozinha após 60 segundos sem apertar botões durante a reprodução (ajustável em sori.cfg).",
  hf_power = "Não use o botão Power: ele coloca o console em repouso e para a música.",
}

S.it = {
  music = "Musica",
  albums_1 = "%d album", albums = "%d album",
  tracks_1 = "%d brano", tracks = "%d brani",
  scanning = "Ricerca della musica",
  found = "%d brani trovati",
  empty_title = "Nessuna musica trovata",
  empty_hint = "Aggiungi album nella cartella:",
  empty_hint2 = "Poi premi X per cercare di nuovo.",
  still_scanning = "Ricerca in corso… %d",
  all_title = "Mescola tutto",
  all_sub = "Tutta la tua musica in ordine casuale",
  various = "Artisti vari",
  play_album = "Ascolta l'album",
  shuffle_hint = "X  casuale",
  nothing_playing = "Nessuna riproduzione",
  now_playing = "In riproduzione",
  track_of = "Brano %d di %d",
  loading = "caricamento…",
  settings = "Impostazioni",
  theme = "Tema", dark = "Scuro", light = "Chiaro",
  accent = "Colore principale",
  c_bleu = "Blu", c_corail = "Corallo", c_jaune = "Giallo", c_menthe = "Menta",
  c_violet = "Viola", c_rose = "Rosa", c_album = "Copertina",
  album_note = "(colore di ogni album)", custom = "Personalizzato",
  language = "Lingua", auto = "Automatica (console)",
  h_choose = "Scegli", h_open = "Apri", h_list = "Lista", h_grid = "Griglia",
  h_listen = "Ascolta", h_shuffle = "Mescola", h_back = "Indietro",
  h_prev = "Precedente", h_next = "Successivo", h_seek = "Avanza", h_volume = "Volume",
  h_vol_down = "Più piano", h_vol_up = "Più forte", h_change = "Cambia",
  favorites = "Preferiti", h_fav = "Preferito", h_random = "Casuale",
  fav_added = "Aggiunto ai preferiti", fav_removed = "Rimosso dai preferiti",
  fav_empty = "Ancora nessun preferito", fav_empty_hint = "Premi Y su un brano per aggiungerlo qui.",
  view = "Visualizzazione", library = "Libreria", rescan = "Cerca musica",
  by_label = "Mostra per", by_albums = "Album", by_artists = "Artisti",
  artists_1 = "%d artista", artists = "%d artisti",
  no_album = "Senza album", unknown_artist = "Artista sconosciuto",
  -- Aiuto
  help = "Aiuto e scorciatoie", help_sub = "Tutto quello che puoi fare, e i tasti",
  h_scroll = "Scorri", key_any = "Un tasto",
  hs_features = "Cosa puoi fare",
  hf_1 = "Ascoltare la tua musica album per album, con le copertine.",
  hf_2 = "La musica viene cercata nella cartella MUSIC delle schede SD1 e SD2.",
  hf_3 = "La cartella Preferiti (stella gialla), sempre per prima, raccoglie i tuoi brani preferiti. Gli album preferiti salgono in cima alla lista.",
  hf_4 = "Riprodurre tutta la tua musica in ordine casuale, o un solo album.",
  hf_5 = "Ripetere tutto o un solo brano, tornare indietro o avanzare nel brano.",
  hf_6 = "Spegnere lo schermo mentre la musica continua.",
  hf_7 = "Nelle Impostazioni: tema scuro o chiaro, colore, lingua, griglia o elenco, per album o per artisti, nuova ricerca della musica.",
  hs_everywhere = "Ovunque", hs_albums = "Elenco degli album", hs_album = "Dentro un album",
  hs_now = "In riproduzione", hs_screen = "Schermo spento",
  k_prevnext = "Brano precedente / successivo",
  k_shuffle_all = "Tutta la musica in ordine casuale",
  k_volume = "Abbassa / alza il volume",
  k_screen_off = "Spegni lo schermo (la musica continua)",
  k_quit = "Esci dall'app",
  k_move = "Spostarsi", k_open = "Apri", k_fav_album = "Album preferito",
  k_now = "Schermata di riproduzione", k_settings = "Impostazioni",
  k_play = "Ascolta l'album o il brano scelto",
  k_shuffle_album = "Album in ordine casuale",
  k_fav_track = "Brano preferito (su «Ascolta l'album»: album preferito)",
  k_back = "Indietro", k_pause = "Riproduci / pausa", k_shuffle_toggle = "Casuale sì / no",
  k_fav_now = "Brano preferito", k_repeat = "Ripeti: no, tutto, un solo brano",
  k_seek = "Indietro / avanti di 10 secondi",
  k_wake = "Riaccendi lo schermo (L1, R1, L2 e R2 funzionano senza riaccenderlo)",
  hf_screen = "Lo schermo si spegne da solo dopo 60 secondi senza premere tasti durante la riproduzione (regolabile in sori.cfg).",
  hf_power = "Non usare il tasto Power: mette la console in standby e ferma la musica.",
}

S.de = {
  music = "Musik",
  albums_1 = "%d Album", albums = "%d Alben",
  tracks_1 = "%d Titel", tracks = "%d Titel",
  scanning = "Musik wird gesucht",
  found = "%d Titel gefunden",
  empty_title = "Keine Musik gefunden",
  empty_hint = "Lege Alben in diesen Ordner:",
  empty_hint2 = "Drücke dann X, um erneut zu suchen.",
  still_scanning = "Suche läuft… %d",
  all_title = "Alles mischen",
  all_sub = "Deine ganze Musik, zufällig gemischt",
  various = "Verschiedene Interpreten",
  play_album = "Album anhören",
  shuffle_hint = "X  Zufall",
  nothing_playing = "Keine Wiedergabe",
  now_playing = "Wiedergabe",
  track_of = "Titel %d von %d",
  loading = "wird geladen…",
  settings = "Einstellungen",
  theme = "Design", dark = "Dunkel", light = "Hell",
  accent = "Hauptfarbe",
  c_bleu = "Blau", c_corail = "Koralle", c_jaune = "Gelb", c_menthe = "Minze",
  c_violet = "Violett", c_rose = "Rosa", c_album = "Cover",
  album_note = "(Farbe jedes Albums)", custom = "Benutzerdefiniert",
  language = "Sprache", auto = "Automatisch (Konsole)",
  h_choose = "Wählen", h_open = "Öffnen", h_list = "Liste", h_grid = "Raster",
  h_listen = "Anhören", h_shuffle = "Mischen", h_back = "Zurück",
  h_prev = "Vorheriger", h_next = "Nächster", h_seek = "Spulen", h_volume = "Lautstärke",
  h_vol_down = "Leiser", h_vol_up = "Lauter", h_change = "Ändern",
  favorites = "Favoriten", h_fav = "Favorit", h_random = "Zufall",
  fav_added = "Zu Favoriten hinzugefügt", fav_removed = "Aus Favoriten entfernt",
  fav_empty = "Noch keine Favoriten", fav_empty_hint = "Drücke Y bei einem Titel, um ihn hier hinzuzufügen.",
  view = "Ansicht", library = "Mediathek", rescan = "Musik suchen",
  by_label = "Anzeigen nach", by_albums = "Alben", by_artists = "Interpreten",
  artists_1 = "%d Interpret", artists = "%d Interpreten",
  no_album = "Ohne Album", unknown_artist = "Unbekannter Interpret",
  -- Hilfe
  help = "Hilfe und Tastenkürzel", help_sub = "Alles, was du tun kannst, und die Tasten",
  h_scroll = "Blättern", key_any = "Eine Taste",
  hs_features = "Was du tun kannst",
  hf_1 = "Deine Musik Album für Album hören, mit Covern.",
  hf_2 = "Musik wird im Ordner MUSIC der Karten SD1 und SD2 gesucht.",
  hf_3 = "Der Ordner Favoriten (gelber Stern), immer an erster Stelle, sammelt deine Lieblingstitel. Lieblingsalben rücken an den Anfang der Liste.",
  hf_4 = "Deine ganze Musik zufällig abspielen, oder ein einzelnes Album.",
  hf_5 = "Alles oder einen einzelnen Titel wiederholen, im Titel zurück- oder vorspulen.",
  hf_6 = "Den Bildschirm ausschalten, während die Musik weiterläuft.",
  hf_7 = "In den Einstellungen: dunkles oder helles Design, Farbe, Sprache, Raster oder Liste, nach Alben oder Interpreten, neue Musiksuche.",
  hs_everywhere = "Überall", hs_albums = "Albenliste", hs_album = "In einem Album",
  hs_now = "Wiedergabe", hs_screen = "Bildschirm aus",
  k_prevnext = "Vorheriger / nächster Titel",
  k_shuffle_all = "Ganze Musik zufällig",
  k_volume = "Lautstärke leiser / lauter",
  k_screen_off = "Bildschirm aus (Musik läuft weiter)",
  k_quit = "App beenden",
  k_move = "Bewegen", k_open = "Öffnen", k_fav_album = "Lieblingsalbum",
  k_now = "Wiedergabe-Bildschirm", k_settings = "Einstellungen",
  k_play = "Album oder gewählten Titel hören",
  k_shuffle_album = "Album zufällig",
  k_fav_track = "Lieblingstitel (bei „Album hören“: Lieblingsalbum)",
  k_back = "Zurück", k_pause = "Wiedergabe / Pause", k_shuffle_toggle = "Zufall an / aus",
  k_fav_now = "Lieblingstitel", k_repeat = "Wiederholen: aus, alle, ein Titel",
  k_seek = "10 Sekunden zurück / vor",
  k_wake = "Bildschirm wieder an (L1, R1, L2 und R2 gehen, ohne ihn einzuschalten)",
  hf_screen = "Der Bildschirm geht während der Wiedergabe nach 60 Sekunden ohne Tastendruck von selbst aus (einstellbar in sori.cfg).",
  hf_power = "Benutze nicht die Power-Taste: Sie versetzt die Konsole in den Ruhezustand und stoppt die Musik.",
}

-- texte traduit (avec format %d / %s éventuel), repli sur l'anglais puis sur la clé
function I.t(key, ...)
  local s = (S[I.lang] and S[I.lang][key]) or S.en[key] or key
  if select("#", ...) > 0 then s = s:format(...) end
  return s
end

-- pluriel : I.n("albums", 3) -> "3 albums", I.n("albums", 1) -> "1 album"
function I.n(key, n) return I.t(n == 1 and (key .. "_1") or key, n) end

-- "fr_FR.UTF-8", "Français", "French", "fr"… -> code connu ou nil
local function code(s)
  if not s then return nil end
  s = s:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if s == "" or s == "c" or s == "posix" then return nil end
  if s:find("^fr") or s:find("^fran") then return "fr" end
  if s:find("^en") then return "en" end
  if s:find("^es") or s:find("^spa") or s:find("^espa") or s:find("^castellano") then return "es" end
  if s:find("^pt") or s:find("^portu") then return "pt" end
  if s:find("^it") then return "it" end
  if s:find("^de") or s:find("^deut") or s:find("^germ") then return "de" end
  return nil
end

local function readFile(p)
  local f = io.open(p, "r")
  if not f then return nil end
  local d = f:read("*a"); f:close()
  return d
end

-- Langue de la console : réglage muOS, puis variables d'environnement
function I.detect()
  local files = {
    "/run/muos/global/settings/general/language",
    "/opt/muos/config/settings/general/language",
    "/opt/muos/config/language",
  }
  for _, p in ipairs(files) do
    local c = code(readFile(p))
    if c then return c end
  end
  local ini = readFile("/opt/muos/config/config.ini")
  if ini then
    local c = code(ini:match("\n%s*language%s*=%s*([^\r\n]+)"))
    if c then return c end
  end
  for _, v in ipairs({ "SORI_LANG", "LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG" }) do
    local c = code(os.getenv(v))
    if c then return c end
  end
  return "en"
end

-- choice = "auto" ou un code ("fr", "en"…)
function I.set(choice)
  choice = (choice or "auto"):lower()
  if choice ~= "auto" and not S[choice] then choice = code(choice) or "auto" end
  I.choice = choice
  I.lang = (choice == "auto") and I.detect() or choice
  if not S[I.lang] then I.lang = "en" end
end

function I.label(id)
  if id == "auto" then return I.t("auto") end
  for _, c in ipairs(I.choices) do if c.id == id then return c.label end end
  return id
end

return I
