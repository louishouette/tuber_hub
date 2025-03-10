Age en printemps
Chaque 1er décembre, une parcelle prend un an, à condition qu'elle ait été plantée avant le 1er janvier de la première année considérée.
Formule Excel pour calculer l'âge de la parcelle en C1, en fonction de la date de plantation en A1 et de la date du 1er décembre de la saison en cours en B1 : =SI(A1<DATE(ANNEE(B1);1;1);ANNEE(B1)-ANNEE(A1);0)
