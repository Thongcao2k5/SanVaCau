import '../../../core/network/api_client.dart';
import '../models/branch_racket_service.dart';

class RacketServiceApi {
  RacketServiceApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // Retained so this data source can switch back to the backend after UI testing.
  // ignore: unused_field
  final ApiClient _apiClient;

  Future<List<BranchRacketService>> getAvailableServices(
    String branchId,
  ) async {
    return const [
      BranchRacketService(
        id: 's1',
        branchId: 'br1',
        serviceId: 'srv1',
        service: RacketServiceInfo(
          id: 'srv1',
          name: 'Đan vợt cầu lông',
          description: 'Đan vợt chuyên nghiệp',
          imageUrl: 'https://cdn.shopvnb.com/uploads/gallery/vot-cau-long-yonex-astrox-99-pro-trang-bach-ho-chinh-hang_1631584067.webp',
        ),
        referencePrice: 50000,
        estimatedDuration: '30 phút',
      ),
      BranchRacketService(
        id: 's2',
        branchId: 'br1',
        serviceId: 'srv2',
        service: RacketServiceInfo(
          id: 'srv2',
          name: 'Quấn cán vợt',
          description: 'Quấn cán chống mồ hôi',
          imageUrl: 'https://cdn.shopvnb.com/uploads/gallery/vot-cau-long-victor-thruster-f-claw-tai-tzu-ying-chinh-hang-2_1688691523.webp',
        ),
        referencePrice: 20000,
        estimatedDuration: '10 phút',
      ),
    ];
  }
}
