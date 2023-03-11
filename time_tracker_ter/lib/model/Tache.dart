class Tache{
  int id;
  String nom;
  String couleur;
  int id_categorie;
  int temps_ecoule;

  Tache({this.id, this.nom, this.couleur, this.id_categorie, this.temps_ecoule});

  Tache.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        nom = map['nom'],
        couleur = map['couleur'],
        id_categorie = map['id_categorie'],
        temps_ecoule = map['temps_ecoule'];




  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'couleur': couleur,
      'id_categorie': id_categorie,
      'temps_ecoule': temps_ecoule,
    };
  }





}