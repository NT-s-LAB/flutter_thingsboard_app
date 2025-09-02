import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thingsboard_app/config/routes/router.dart';
import 'package:thingsboard_app/constants/assets_path.dart';
import 'package:thingsboard_app/core/context/tb_context_widget.dart';
import 'package:thingsboard_app/core/entity/entities_base.dart';
import 'package:thingsboard_app/core/entity/entities_grid.dart';
import 'package:thingsboard_app/generated/l10n.dart';
import 'package:thingsboard_app/locator.dart';
import 'package:thingsboard_app/modules/device/devices_base.dart';
import 'package:thingsboard_app/thingsboard_client.dart';
import 'package:thingsboard_app/utils/services/device_profile/device_profile_cache.dart';
import 'package:thingsboard_app/utils/services/device_profile/model/cached_device_profile.dart';
import 'package:thingsboard_app/utils/utils.dart';
import 'package:thingsboard_app/widgets/tb_app_bar.dart';

class DevicesMainPage extends TbContextWidget {
  DevicesMainPage(super.tbContext, {super.key});

  @override
  State<StatefulWidget> createState() => _DevicesMainPageState();
}

class _DevicesMainPageState extends TbContextState<DevicesMainPage>
    with AutomaticKeepAliveClientMixin<DevicesMainPage> {
  // Sử dụng DeviceQueryController để truy vấn danh sách thiết bị.
  late final DeviceQueryController _deviceQueryController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller để lấy tất cả thiết bị.
    _deviceQueryController = DeviceQueryController();
  }

  @override
  bool get wantKeepAlive {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Tạo widget lưới thiết bị.
    final devicesGrid = DevicesGrid(
      tbContext,
      _deviceQueryController,
    );

    // Tạo tiêu đề cho AppBar.
    final title = Text(S.of(context).allDevices);

    // Tạo AppBar với nút tìm kiếm.
    final appBar = TbAppBar(
      tbContext,
      title: title,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Điều hướng đến trang danh sách có bật chế độ tìm kiếm.
            getIt<ThingsboardAppRouter>()
                // translate-me-ignore-next-line
                .navigateTo('/deviceList?search=true');
          },
        ),
      ],
    );

    // Trả về Scaffold chứa danh sách tất cả các thiết bị.
    return Scaffold(
      appBar: appBar,
      body: devicesGrid,
    );
  }

  @override
  void dispose() {
    _deviceQueryController.dispose();
    super.dispose();
  }
}

// Widget để hiển thị các thiết bị dưới dạng lưới.
class DevicesGrid extends BaseEntitiesWidget<EntityData, EntityDataQuery>
    with DevicesBase, EntitiesGridStateBase {
  DevicesGrid(
    super.tbContext,
    super.pageKeyController, {
    super.key,
  });

  @override
  Widget buildEntityGridCard(BuildContext context, EntityData device) {
    // Sử dụng widget Card tùy chỉnh.
    return DeviceGridCard(tbContext, device: device);
  }

  @override
  double? gridChildAspectRatio() {
    // Điều chỉnh tỉ lệ khung hình của card.
    return 156 / 190;
  }
}

// Widget Card để hiển thị thông tin chi tiết của một thiết bị.
class DeviceGridCard extends TbContextWidget {
  DeviceGridCard(super.tbContext, {required this.device, super.key});
  final EntityData device;

  @override
  State<StatefulWidget> createState() => _DeviceGridCardState();
}

class _DeviceGridCardState extends TbContextState<DeviceGridCard> {
  late Future<CachedDeviceProfileInfo> deviceProfileFuture;

  @override
  void initState() {
    super.initState();
    _loadDeviceProfile();
  }

  @override
  void didUpdateWidget(DeviceGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.field('type')! != widget.device.field('type')!) {
      _loadDeviceProfile();
    }
  }

  void _loadDeviceProfile() {
    deviceProfileFuture = DeviceProfileCache.getDeviceProfileInfo(
      tbClient,
      widget.device.field('type')!,
      widget.device.entityId.id!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CachedDeviceProfileInfo>(
      future: deviceProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final profile = snapshot.data!;
          final isActive = widget.device.attribute('active') == 'true';
          Widget image;
          if (profile.info.image != null) {
            image = Utils.imageFromTbImage(context, tbClient, profile.info.image,
                width: 80, height: 80);
          } else {
            image = SvgPicture.asset(ThingsboardImage.deviceProfilePlaceholder,
                width: 80, height: 80, semanticsLabel: 'Device profile');
          }

          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Expanded(
                  child:
                      Padding(padding: const EdgeInsets.all(12), child: image),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.device.field('name')!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.device.field('type')!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE0F2E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle,
                          size: 10,
                          color: isActive ? const Color(0xFF008A00) : Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        isActive
                            ? S.of(context).active
                            : S.of(context).inactive,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? const Color(0xFF008A00) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

