from PIL import Image
import os

def create_icon(source_path, output_path, size):
    if not os.path.exists(os.path.dirname(output_path)):
        os.makedirs(os.path.dirname(output_path))
    
    with Image.open(source_path) as img:
        # Convertir en RGBA si ce n'est pas déjà le cas
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Redimensionner l'image
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(output_path, 'PNG')

def generate_ios_icons(source_icon):
    # Définir les tailles d'icônes requises pour iOS
    icon_sizes = {
        # iPhone
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        
        # iPad
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        
        # App Store
        "Icon-App-1024x1024@1x.png": 1024,
    }

    # Créer les icônes
    base_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for icon_name, size in icon_sizes.items():
        output_path = os.path.join(base_path, icon_name)
        create_icon(source_icon, output_path, size)

    # Créer les images de lancement
    launch_sizes = {
        "LaunchImage.png": 512,
        "LaunchImage@2x.png": 1024,
        "LaunchImage@3x.png": 1536
    }

    for launch_name, size in launch_sizes.items():
        output_path = os.path.join("ios/Runner/Assets.xcassets/LaunchImage.imageset", launch_name)
        create_icon(source_icon, output_path, size)

if __name__ == "__main__":
    # Vérifier si le dossier assets existe
    if not os.path.exists("assets"):
        os.makedirs("assets")
    
    # Créer une icône de base bleue avec le texte "CE"
    icon_size = 1024
    icon = Image.new('RGBA', (icon_size, icon_size), (0, 122, 255, 255))
    
    # Sauvegarder l'icône de base
    icon_path = "assets/app_icon.png"
    icon.save(icon_path, 'PNG')
    
    # Générer toutes les tailles d'icônes
    generate_ios_icons(icon_path)
