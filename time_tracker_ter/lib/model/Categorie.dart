class Categorie{
  int id;
  String nom;
  String couleur;
  String temps_ecoule;
  int id_categorie_sup;

  Categorie({this.id, this.nom, this.couleur, this.temps_ecoule, this.id_categorie_sup});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'couleur': couleur,
      'temps_ecoule': temps_ecoule,
      'id_categorie_sup': id_categorie_sup,
    };
  }

  Categorie.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        nom = map['nom'],
        couleur = map['couleur'],
        temps_ecoule = map['temps_ecoule'],
        id_categorie_sup = map['id_categorie_sup'];

  @override
  String toString() {
    return 'Categorie{id: $id, nom: $nom, couleur: $couleur, temps_ecoule: $temps_ecoule, id_categorie_sup: $id_categorie_sup}';
  }
}