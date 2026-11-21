import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import '../models/machine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class LocalMachinePhotoCard extends StatefulWidget {
  const LocalMachinePhotoCard({super.key, required this.machine});
  final Machine machine;
  @override
  State<LocalMachinePhotoCard> createState() => _LocalMachinePhotoCardState();
}
class _LocalMachinePhotoCardState extends State<LocalMachinePhotoCard> {
  bool working = false;

  Future<void> _pick() async {
    if (working) return;
    setState(() => working = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 55,
        maxWidth: 600, maxHeight: 600);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      AppScope.of(context).setLocalPhoto(widget.machine.id, bytes);
      await AppScope.of(context).flushPendingWrites();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto do aparelho salva localmente.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Não foi possível adicionar a foto: $error')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final photo = app.localPhoto(widget.machine.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.deepBlue)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.photo_camera_outlined, color: AppTheme.electricLime),
          const SizedBox(width: 10),
          const Expanded(child: Text('Foto deste aparelho',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
          if (photo != null) IconButton(
            tooltip: 'Remover foto local', icon: const Icon(Icons.delete_outline),
            onPressed: () => app.setLocalPhoto(widget.machine.id, null)),
        ]),
        const SizedBox(height: 7),
        Text('Perfil: ${app.selectedGymName}',
          style: const TextStyle(color: AppTheme.iceBlue,fontSize: 12)),
        if (photo != null) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.memory(photo, height: 168, width: double.infinity,
              fit: BoxFit.cover)),
        ],
        const SizedBox(height: 11),
        OutlinedButton.icon(
          onPressed: working ? null : _pick,
          icon: Icon(working ? Icons.hourglass_top : Icons.add_a_photo_outlined),
          label: Text(working ? 'Importando foto...' :
            photo == null ? 'Escolher foto da galeria' : 'Trocar foto'),
        ),
        const SizedBox(height: 5),
        const Text('Imagem privada, comprimida e guardada com o backup local.',
          style: TextStyle(color: AppTheme.iceBlue,fontSize: 12)),
      ]),
    );
  }
}
