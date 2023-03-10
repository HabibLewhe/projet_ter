class Categorie{
  int id;
  String nom;
  String couleur;
  int id_categorie_sup;
  int id_user;

  Categorie({this.id, this.nom, this.couleur, this.id_categorie_sup, this.id_user});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'couleur': couleur,
      'id_categorie_sup': id_categorie_sup,
      'id_user': id_user,
    };
  }


  Categorie.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        nom = map['nom'],
        couleur = map['couleur'],
        id_categorie_sup = map['id_categorie_sup'],
        id_user = map['id_user'];

  @override
  String toString() {
    return 'Categorie{id: $id, nom: $nom, couleur: $couleur, id_categorie_sup: $id_categorie_sup, id_user: $id_user}';
  }
}