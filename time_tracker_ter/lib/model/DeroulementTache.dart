class DeroulementTache{
  int id;
  int id_tache;
  String date_debut;
  String date_fin;
  double Latitude;
  double Longitude;

  DeroulementTache({this.id, this.id_tache, this.date_debut, this.date_fin, this.Latitude, this.Longitude});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_tache' : id_tache,
      'date_debut': date_debut,
      'date_fin': date_fin,
      'latitude': Latitude,
      'longitude': Longitude
    };
  }

  DeroulementTache.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        id_tache = map['id_tache'],
        date_debut = map['date_debut'],
        date_fin = map['date_fin'],
        Latitude = map['latitude'],
        Longitude = map['longitude'];

  @override
  String toString() {
    return 'DeroulementTache{id: $id, id_tache: $id_tache, date_debut: $date_debut, date_fin: $date_fin, latitude: $Latitude, longitude: $Longitude}';
  }

}