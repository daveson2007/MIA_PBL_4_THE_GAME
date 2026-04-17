import flet as ft
from collections import Counter
from utils.deck import Deck
from utils.component import create_ui_card

# Dictionnaire des valeurs pour l'évaluation
CARD_VALUES = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'V': 11, 'D': 12, 'R': 13, 'A': 14
}

def evaluate_poker_hand(hand):
    """
    Algorithme complet pour évaluer la valeur d'une main de poker.
    Retourne la nomenclature officielle de la main.
    """
    if len(hand) < 5:
        return "En attente..."

    # Extraction des valeurs numériques et des couleurs
    values = sorted([CARD_VALUES[c.rank] for c in hand], reverse=True)
    suits = [c.suit for c in hand]

    # Vérification de la Couleur (Flush)
    is_flush = len(set(suits)) == 1

    # Vérification de la Suite (Straight)
    is_straight = False
    if len(set(values)) == 5:
        # Suite classique
        if values[0] - values[4] == 4:
            is_straight = True
        # Cas spécial : La roue (As, 2, 3, 4, 5)
        elif values == [14, 5, 4, 3, 2]:
            is_straight = True

    # Comptage des occurrences (pour Paires, Brelan, Carré, Full)
    counts = Counter(values)
    frequencies = sorted(counts.values(), reverse=True)

    # Nomenclature officielle des mains (de la plus forte à la plus faible)
    if is_flush and is_straight:
        if values[0] == 14 and values[1] == 13: # As, Roi, Dame, Valet, 10
            return "Quinte Flush Royale"
        return "Quinte Flush"
    
    if frequencies == [4, 1]:
        return "Carré"
    
    if frequencies == [3, 2]:
        return "Full (Main Pleine)"
    
    if is_flush:
        return "Couleur"
    
    if is_straight:
        return "Quinte (Suite)"
    
    if frequencies == [3, 1, 1]:
        return "Brelan"
    
    if frequencies == [2, 2, 1]:
        return "Double Paire"
    
    if frequencies == [2, 1, 1, 1]:
        return "Paire"

    # Si aucune combinaison
    return "Carte Haute"

def get_game_view():
    deck = Deck()
    player_hand = []
    held_cards = [False] * 5
    # Phase 0: Attente, Phase 1: Choix des cartes à garder, Phase 2: Résultat final
    phase = 0

    # Éléments d'interface
    cards_row = ft.Row(wrap=True, spacing=20, alignment=ft.MainAxisAlignment.CENTER)
    result_text = ft.Text("Appuyez sur Distribuer", size=24, weight="bold", color=ft.Colors.BLUE_400)
    instruction_text = ft.Text("", size=16, italic=True)
    
    action_button = ft.ElevatedButton("Distribuer", on_click=lambda e: play_turn(e))

    def show_rules(e):
        """Affiche les règles et la hiérarchie des cartes"""
        rules_content = ft.Column([
            ft.Text("Hiérarchie des cartes :", weight="bold"),
            ft.Text("2 < 3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < Valet (V) < Dame (D) < Roi (R) < As (A)\n"),
            ft.Text("Nomenclature des mains (du plus fort au plus faible) :", weight="bold"),
            ft.Text("1. Quinte Flush Royale : A, R, D, V, 10 de la même couleur."),
            ft.Text("2. Quinte Flush : 5 cartes qui se suivent de la même couleur."),
            ft.Text("3. Carré : 4 cartes de même valeur (ex: 4 Rois)."),
            ft.Text("4. Full : 3 cartes de même valeur + 2 cartes de même valeur (Brelan + Paire)."),
            ft.Text("5. Couleur (Flush) : 5 cartes de la même couleur (ex: 5 Piques), sans se suivre."),
            ft.Text("6. Quinte (Suite) : 5 cartes qui se suivent, de couleurs différentes."),
            ft.Text("7. Brelan : 3 cartes de même valeur."),
            ft.Text("8. Double Paire : 2 paires distinctes."),
            ft.Text("9. Paire : 2 cartes de même valeur."),
            ft.Text("10. Carte Haute : Aucune combinaison, la carte la plus haute gagne.")
        ], scroll=ft.ScrollMode.AUTO, height=400)

        dialog = ft.AlertDialog(
            title=ft.Text("Règles du Poker"),
            content=rules_content,
            actions=[ft.TextButton("Fermer", on_click=lambda e: close_dialog(dialog))]
        )
        e.page.dialog = dialog
        dialog.open = True
        e.page.update()

    def close_dialog(dialog):
        dialog.open = False
        dialog.page.update()

    def update_ui():
        cards_row.controls.clear()
        
        for i, card in enumerate(player_hand):
            # Enveloppe la carte dans un GestureDetector pour permettre le clic
            card_ui = create_ui_card(card)
            
            # Effet visuel si la carte est gardée
            if held_cards[i] and phase == 1:
                card_ui.border = ft.border.all(3, ft.Colors.GREEN)
                card_ui.opacity = 0.5
            else:
                card_ui.border = ft.border.all(1, ft.Colors.WHITE24)
                card_ui.opacity = 1.0

            clickable_card = ft.GestureDetector(
                content=card_ui,
                on_tap=lambda e, index=i: toggle_hold(index, e.page)
            )
            
            cards_row.controls.append(ft.Column([
                clickable_card,
                ft.Text("GARDÉE" if held_cards[i] else "", color=ft.Colors.GREEN, weight="bold")
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER))
            
        result_text.value = evaluate_poker_hand(player_hand)

    def toggle_hold(index, page):
        nonlocal phase, held_cards
        # ON AUTORISE LE CLIC SEULEMENT EN PHASE 1 (après la distribution)
        if phase == 1:
            held_cards[index] = not held_cards[index]
            update_ui()
            page.update()

    def play_turn(e):
        nonlocal deck, player_hand, held_cards, phase

        if phase == 0 or phase == 2:
            # --- ÉTAPE 1 : DISTRIBUTION ---
            deck = Deck() # On remélange tout
            player_hand = [deck.draw() for _ in range(5)]
            held_cards = [False] * 5
            
            result_text.value = "Choisissez vos cartes"
            result_text.color = ft.Colors.BLUE_400
            action_button.text = "Valider et échanger"
            phase = 1 # On passe en mode "clic autorisé"
            
        elif phase == 1:
            # --- ÉTAPE 2 : ÉCHANGE ET RÉSULTAT ---
            for i in range(5):
                if not held_cards[i]:
                    player_hand[i] = deck.draw()
            
            # Évaluation finale
            final_res = evaluate_poker_hand(player_hand)
            result_text.value = f"RÉSULTAT : {final_res}"
            result_text.color = ft.Colors.GREEN_400
            
            if final_res != "Carte Haute":
                # Si c'est autre chose qu'une Carte Haute, c'est une victoire !
                instruction_text.value = "✨ BIEN JOUÉ ! Vous avez gagné ! ✨"
                instruction_text.color = ft.Colors.GREEN_400
                result_text.color = ft.Colors.AMBER_300 # On fait briller le résultat
            else:
                # Sinon, c'est perdu
                instruction_text.value = "Dommage... Aucune combinaison trouvée."
                instruction_text.color = ft.Colors.RED_400
                result_text.color = ft.Colors.WHITE
    
            action_button.text = "Nouveau Tirage"
            phase = 2 # On passe en mode "fin de partie"
            # On ne réinitialise pas held_cards ici pour que le joueur voie ce qu'il a gardé

        update_ui()
        e.page.update()

    return ft.Column([
        ft.Row([
            ft.Text("Video Poker (5 Cartes)", size=30, weight="bold"),
            ft.IconButton(icon=ft.Icons.HELP_OUTLINE, tooltip="Voir les règles", on_click=show_rules)
        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
        
        ft.Divider(),
        
        ft.Container(
            content=result_text,
            alignment=ft.Alignment(0, 0),
            padding=20
        ),
        
        ft.Container(
            content=cards_row,
            alignment=ft.Alignment(0, 0),
            padding=20,
            height=200
        ),
        
        ft.Container(
            content=instruction_text,
           alignment=ft.Alignment(0, 0),
        ),
        
        ft.Container(
            content=action_button,
            alignment=ft.Alignment(0, 0),
            padding=20
        )
    ], expand=True)