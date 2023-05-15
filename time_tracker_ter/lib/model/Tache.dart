class Tache {
  int id;
  String nom;
  String couleur;
  int id_categorie;
  String temps_ecoule;

  Tache(
      {this.id, this.nom, this.couleur, this.id_categorie, this.temps_ecoule});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'couleur': couleur,
      'id_categorie': id_categorie,
      'temps_ecoule': temps_ecoule
    };
  }

  Tache.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        nom = map['nom'],
        couleur = map['couleur'],
        id_categorie = map['id_categorie'],
        temps_ecoule = map['temps_ecoule'];

  @override
  String toString() {
    return 'Tache{id: $id, nom: $nom, couleur: $couleur, id_categorie: $id_categorie, temps_ecoule: $temps_ecoule}';
  }

  // redéfinition des comparateurs pour que deux objets Tache soient jugés égaux
  // si tous les paramètres ont la même valeur
  @override
  int get hashCode {
    return id.hashCode ^
    nom.hashCode ^
    couleur.hashCode ^
    id_categorie.hashCode ^
    temps_ecoule.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tache &&
        id == other.id &&
        nom == other.nom &&
        couleur == other.couleur &&
        id_categorie == other.id_categorie &&
        temps_ecoule == other.temps_ecoule;
  }

}
