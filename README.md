# Ninstaah præsentere Moderne Seedbox løsning!
*Installation via denne kommando (CentOS 7, Hetzner)*
 
```
wget https://raw.githubusercontent.com/ninstaah/seedbox/master/setup.sh
chmod +x setup.sh
./setup.sh
```

## Proriteter for løsningen
* Lav ressource forbrug
* God fil administration
* Sikkerhed
* Brugervenlighed


### Opsætning af Trakt.tv og Flexget

#### - Trakt.tv delen
1. Opret en bruger på Trakt.tv
2. Bekræft brugeren, og logind
3. Opret en liste ved navn "film" og en ved navn "serier"

#### - Flexget delen
1. Gå til https://file.example.com (admin/admin - husk at ændre dette!)
2. Gå til https://file.example.com/files/flexget/variables.yml
3. Ændre `trakt: 'ninstaah'` til dit eget brugernavn på trakt.tv
4. Åben tab med https://danishbits.org/rss.php
5. Kopier links fra step 4 til deres pladser i flexget/variables.yml (step 2)
6. Gem https://file.example.com/files/flexget/variables.yml)
7. Gå til https://file.example.com/files/flexget/config.yml)
8. I terminalen skal du godkende flexget hos trakt.tv: `flexget trakt auth ninstaah` (brug dit brugernavn!)