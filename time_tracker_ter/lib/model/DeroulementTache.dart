class DeroulementTache{
  int id;
  int id_tache;
  String date_debut;
  String date_fin;
  double latitude;
  double longitude;

  DeroulementTache({this.id, this.id_tache, this.date_debut, this.date_fin, this.latitude, this.longitude});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_tache' : id_tache,
      'date_debut': date_debut,
      'date_fin': date_fin,
      'latitude': latitude,
      'longitude': longitude
    };
  }

  DeroulementTache.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        id_tache = map['id_tache'],
        date_debut = map['date_debut'],
        date_fin = map['date_fin'],
        latitude = map['Latitude'],
        longitude = map['Longitude'];

  @override
  String toString() {
    return 'DeroulementTache{id: $id, id_tache: $id_tache, date_debut: $date_debut, date_fin: $date_fin, latitude: $latitude, longitude: $longitude}';
  }

}