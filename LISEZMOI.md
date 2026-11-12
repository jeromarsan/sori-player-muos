# Sori Player — lecteur de musique pour muOS

Testé sur Anbernic RG40XXV avec muOS 2606.0 (Andromeda). *English version: [README.md](README.md)*

1. Télécharge `SoriPlayer-vX.Y.Z.zip` dans les Releases GitHub, puis copie le dossier **SoriPlayer** dans `/Primary Storage/MUOS/application/` (le dossier `MUOS/application` de la carte SD principale).
2. Il faut LÖVE 11.x aarch64 : soit `SoriPlayer/bin/love` (+ `bin/lib/`), soit le runtime PortMaster (`love_11.5`).
3. Musique : le dossier `MUSIC/` à la racine de chaque carte SD est analysé (`/mnt/mmc/MUSIC` sur la SD1 et `/mnt/sdcard/MUSIC` sur la SD2 ; `Music` ou `music` marchent aussi). Un dossier par album, pochette `cover.jpg` ou intégrée aux tags. Pendant la lecture, un morceau qui a sa propre image intégrée (ajoutée avec Mp3tag par exemple) l'affiche ; sinon c'est la pochette de l'album. Autre dossier : `music_dir=` dans `sori.cfg`.
4. Problème ? lis `sori.log`. Si A et B sont inversés : `inverser_ab=1` dans `sori.cfg` (X et Y : `inverser_xy=1`) (et `debug_input=1` pour voir les boutons détectés).
5. Réglages (Select depuis la liste des albums) : thème sombre/clair, couleur principale (bleu par défaut), langue (automatique = langue de la console ; français, anglais, espagnol, portugais, italien, allemand ; sinon anglais), affichage grille/liste, nouvelle recherche de la musique, et **Aide et raccourcis** (toutes les fonctions et tous les boutons, traduits dans les 6 langues).

Écran éteint, musique qui continue : Menu (appui seul) éteint l'écran, et il s'éteint tout seul après 60 s sans bouton pendant la lecture (`ecran_veille=` dans `sori.cfg`, 0 = jamais). N'importe quel bouton le rallume ; L1/R1 et L2/R2 marchent écran éteint. N'utilise pas le bouton Power : il met la console en veille complète et coupe la musique. Dans muOS, mets « Idle Input Sleep Timeout » sur Disabled.

Partout : L1/R1 titre précédent/suivant · L1+R1 ensemble lecture aléatoire de toute la musique · L2/R2 volume · A ouvrir/pause · B retour · Menu+Start (ou Select+Start) quitter.
Albums : X lecture aléatoire de toute la musique · Y album favori · Select réglages.
Album : X lecture aléatoire de l'album · Y morceau favori (sur « Écouter l'album » : album favori).
Lecture : X aléatoire on/off · Y morceau favori · Select répétition.

Favoris : le dossier « Favoris » (étoile jaune) est toujours en premier, même vide, et regroupe tous les morceaux favoris (Y sur un morceau) ; les albums favoris passent en tête de la liste avec un cœur.

Licence : code sous licence [MIT](LICENSE) © jeromarsan. Police Nunito : SIL Open Font License 1.1 (`assets/Nunito-OFL.txt`).
