import 'package:flutter/material.dart';
import 'package:thingsboard_app/config/routes/router.dart';
import 'package:thingsboard_app/core/context/tb_context_widget.dart';
import 'package:thingsboard_app/generated/l10n.dart';
import 'package:thingsboard_app/locator.dart';
import 'package:thingsboard_app/modules/device/devices_base.dart';
import 'package:thingsboard_app/modules/device/devices_list.dart';
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
    // Tạo widget danh sách thiết bị.
    final devicesList = DevicesList(
      tbContext,
      _deviceQueryController,
      displayDeviceImage: true,
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
      body: devicesList,
    );
  }

  @override
  void dispose() {
    _deviceQueryController.dispose();
    super.dispose();
  }
}
