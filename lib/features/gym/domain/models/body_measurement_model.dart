class BodyMeasurementModel {
  const BodyMeasurementModel({
    required this.id,
    required this.date,
    this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
    this.chestCm,
    this.armCm,
    this.neckCm,
    this.shouldersCm,
    this.forearmCm,
    this.thighCm,
    this.calfCm,
    this.hipCm,
    this.muscleMassKg,
    this.bodyWaterPercent,
    this.heightCm,
    this.photoFrontPath,
    this.photoSidePath,
    this.photoBackPath,
    this.note,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;
  final double? neckCm;
  final double? shouldersCm;
  final double? forearmCm;
  final double? thighCm;
  final double? calfCm;
  final double? hipCm;
  final double? muscleMassKg;
  final double? bodyWaterPercent;
  final double? heightCm;
  final String? photoFrontPath;
  final String? photoSidePath;
  final String? photoBackPath;
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'bodyFatPercent': bodyFatPercent,
        'waistCm': waistCm,
        'chestCm': chestCm,
        'armCm': armCm,
        'neckCm': neckCm,
        'shouldersCm': shouldersCm,
        'forearmCm': forearmCm,
        'thighCm': thighCm,
        'calfCm': calfCm,
        'hipCm': hipCm,
        'muscleMassKg': muscleMassKg,
        'bodyWaterPercent': bodyWaterPercent,
        'heightCm': heightCm,
        'photoFrontPath': photoFrontPath,
        'photoSidePath': photoSidePath,
        'photoBackPath': photoBackPath,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BodyMeasurementModel.fromMap(Map<String, dynamic> map) =>
      BodyMeasurementModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        weightKg: map['weightKg'] as double?,
        bodyFatPercent: map['bodyFatPercent'] as double?,
        waistCm: map['waistCm'] as double?,
        chestCm: map['chestCm'] as double?,
        armCm: map['armCm'] as double?,
        neckCm: map['neckCm'] as double?,
        shouldersCm: map['shouldersCm'] as double?,
        forearmCm: map['forearmCm'] as double?,
        thighCm: map['thighCm'] as double?,
        calfCm: map['calfCm'] as double?,
        hipCm: map['hipCm'] as double?,
        muscleMassKg: map['muscleMassKg'] as double?,
        bodyWaterPercent: map['bodyWaterPercent'] as double?,
        heightCm: map['heightCm'] as double?,
        photoFrontPath: map['photoFrontPath'] as String?,
        photoSidePath: map['photoSidePath'] as String?,
        photoBackPath: map['photoBackPath'] as String?,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
