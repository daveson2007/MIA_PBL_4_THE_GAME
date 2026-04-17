import flet as ft

# Importation des vues (Assure-toi que le dossier est bien nommé "game")
from game.blackjack import get_game_view as view_blackjack
from game.memory import get_game_view as view_memory
from game.president import get_game_view as view_president 
from game.inter import get_game_view as view_inter
from game.belote import get_game_view as view_belote
from game.speed import get_game_view as view_speed
from game.poker import get_game_view as view_poker

def main(page: ft.Page):
    page.title = "Casino International - 7 Jeux"
    page.theme_mode = ft.ThemeMode.DARK
    page.window_width = 1100 
    page.window_height = 800
    page.window_resizable = False # Plus stable pour les jeux

    # Zone de contenu principal
    content_area = ft.Container(expand=True, padding=20)

    # Dictionnaire de navigation
    game_views = {
        0: view_president,
        1: view_inter, 
        2: view_blackjack,
        3: view_memory,
        4: view_belote,
        5: view_speed,
        6: view_poker
    }

    def on_nav_change(e):
        index = e.control.selected_index
        content_area.content = game_views[index]()
        page.update()

    # Menu latéral avec des icônes optimisées
    rail = ft.NavigationRail(
        selected_index=1, 
        label_type=ft.NavigationRailLabelType.ALL,
        min_width=100,
        unselected_label_text_style=ft.TextStyle(color=ft.Colors.BLUE_GREY_400),
        selected_label_text_style=ft.TextStyle(color=ft.Colors.CYAN_ACCENT),
       destinations=[
        ft.NavigationRailDestination(icon=ft.Icons.PERSON, label="Président"), # Simple et efficace
        ft.NavigationRailDestination(icon=ft.Icons.STYLE, label="L'Inter"), 
        ft.NavigationRailDestination(icon=ft.Icons.ATTACH_MONEY, label="Blackjack"),
        ft.NavigationRailDestination(icon=ft.Icons.GRID_VIEW, label="Memory"),
        ft.NavigationRailDestination(icon=ft.Icons.PEOPLE, label="Belote"),
        ft.NavigationRailDestination(icon=ft.Icons.BOLT, label="Speed"),
        ft.NavigationRailDestination(icon=ft.Icons.CABLE, label="Poker"), # Ou Icons.PLAYING_CARDS
    ],
        on_change=on_nav_change,
    )

    # Initialisation sur l'Inter
    content_area.content = game_views[1]()

    # Structure de la page
    page.add(
        ft.Row(
            [
                rail,
                ft.VerticalDivider(width=1),
                content_area
            ],
            expand=True,
        )
    )

if __name__ == "__main__":
    # CRUCIAL : assets_dir permet d'utiliser src="cards/8_Trefle.png" dans tes jeux
    ft.app(target=main, assets_dir="assets")