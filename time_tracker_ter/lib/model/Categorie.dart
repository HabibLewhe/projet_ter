class Categorie {
  int id;
  String nom;
  String couleur;
  int id_categorie_sup;
  int id_user;
  get getId => this.id;

  set setId(id) => this.id = id;

  get getNom => this.nom;

  set setNom(nom) => this.nom = nom;

  get getCouleur => this.couleur;

  set setCouleur(couleur) => this.couleur = couleur;

  get idcategorie_sup => this.id_categorie_sup;

  set idcategorie_sup(value) => this.id_categorie_sup = value;

  get iduser => this.id_user;

  set iduser(value) => this.id_user = value;
  String getNomById(int id) => this.nom;

  Categorie(
      {this.id, this.nom, this.couleur, this.id_categorie_sup, this.id_user});

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
