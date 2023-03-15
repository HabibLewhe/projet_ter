class Tache {
  int id;
  String nom;
  String couleur;
  int id_categorie;
  DateTime temps_ecoule;

  get getId => this.id;

  set setId(id) => this.id = id;

  get getNom => this.nom;

  set setNom(nom) => this.nom = nom;

  get getCouleur => this.couleur;

  set setCouleur(couleur) => this.couleur = couleur;

  get idcategorie => this.id_categorie;

  set idcategorie(value) => this.id_categorie = value;

  get tempsecoule => this.temps_ecoule;

  set tempsecoule(value) => this.temps_ecoule = value;

  Tache.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        nom = map['nom'],
        couleur = map['couleur'],
        temps_ecoule = DateTime.parse(map['temps_ecoule']),
        id_categorie = map['id_categorie'];

  Tache(
      {this.id, this.nom, this.couleur, this.id_categorie, this.temps_ecoule});
}
