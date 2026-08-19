
class LimousineVehicleModel {
  List<LimousineVehicle>? data;
  String? success;

  LimousineVehicleModel({this.data, this.success});

  factory LimousineVehicleModel.fromJson(Map<String, dynamic> json) {
    return LimousineVehicleModel(
      success: json['success']?.toString(),
      data: json['data'] != null
          ? List<LimousineVehicle>.from(
              json['data'].map((x) => LimousineVehicle.fromJson(x)))
          : [],
    );
  }
}

class LimousineVehicle {
  int? id;
  String? name;
  String? pricePerDay;
  String? pricePerHour;
  String? price8h;
  String? price10h;
  String? price12h;
  String? image;
  int? seats;
  String? status;

  LimousineVehicle({
    this.id,
    this.name,
    this.pricePerDay,
    this.pricePerHour,
    this.price8h,
    this.price10h,
    this.price12h,
    this.image,
    this.seats,
    this.status,
  });

  factory LimousineVehicle.fromJson(Map<String, dynamic> json) {
    return LimousineVehicle(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      pricePerDay: json['price_per_day']?.toString(),
      pricePerHour: json['price_per_hour']?.toString(),
      price8h: json['price_8h']?.toString(),
      price10h: json['price_10h']?.toString(),
      price12h: json['price_12h']?.toString(),
      image: json['image']?.toString() ?? json['car_image']?.toString(),
      seats: json['seats'] is int
          ? json['seats']
          : int.tryParse(json['seats']?.toString() ?? ''),
      status: json['status']?.toString(),
    );
  }

  // double get hourlyRate {
  //   if (pricePerHour != null && pricePerHour != '0') {
  //     return double.tryParse(pricePerHour ?? '0') ?? 0;
  //   }
  //   // fallback: derive from price_8h
  //   return (double.tryParse(price8h ?? '0') ?? 0) / 8;
  // }

  // double priceForDuration(int durationHours) {
  //   return hourlyRate * durationHours;
  // }

  double get hourlyRate {
    return (double.tryParse(price8h ?? '0') ?? 0) / 8;
  }
  double priceForDuration(int durationHours) {
    switch (durationHours) {
      case 8:
        return double.tryParse(price8h ?? '0') ?? 0;
      case 10:
        return double.tryParse(price10h ?? '0') ?? 0;
      case 12:
        return double.tryParse(price12h ?? '0') ?? 0;
      default:
        return double.tryParse(price8h ?? '0') ?? 0;
    }
  }
}