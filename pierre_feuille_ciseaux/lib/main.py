import os
import math
import struct
import wave
import threading
import subprocess
import random
from flet import app, Text, Row, ElevatedButton, Container, Column, DecorationImage, BoxFit, Alignment, Image, ColorFilter, BlendMode

def get_asset_path(filename: str) -> str:
    return os.path.normpath(os.path.join(os.path.dirname(__file__), os.pardir, "assets", filename))

def generate_music_file(path: str) -> None:
    if os.path.exists(path):
        return
    sample_rate = 44100
    duration = 12.0
    amplitude = 12000
    frequencies = [219.99, 246.94, 293.66, 349.23, 392.00, 440.00, 466.16, 523.25]
    n_samples = int(duration * sample_rate)
    
    with wave.open(path, "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        frames = bytearray()
        
        for i in range(n_samples):
            t = i / sample_rate
            freq_index = int((i / sample_rate) * len(frequencies))
            freq = frequencies[freq_index % len(frequencies)]
            
            envelope = 1.0 if (i // (sample_rate // 4)) % 2 == 0 else 0.7
            value = int(amplitude * envelope * math.sin(2 * math.pi * freq * t))
            frames.extend(struct.pack("<h", value))
        
        wav.writeframes(frames)


def start_background_music() -> None:
    music_path = get_asset_path("music_jjk.wav")
    generate_music_file(music_path)
    
    def play_music():
        try:
            subprocess.Popen(
                ["powershell", "-NoProfile", "-Command", 
                 f"$player = New-Object System.Media.SoundPlayer '{music_path}'; $player.PlayLooping()"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=0x08000000
            )
        except Exception as e:
            print(f"Erreur musique: {e}")
    
    thread = threading.Thread(target=play_music, daemon=True)
    thread.start()

def main(page):
    page.title = "Pierre Feuille Ciseau"
    page.vertical_alignment = "center"
    page.horizontal_alignment = "center"

    user_score = 0
    comp_score = 0
    choices = [
        ("Pierre", "assets/pierre.png"),
        ("Feuille", "assets/papier.png"),
        ("Ciseau", "assets/ciseaux.png"),
        ("Puits", "assets/puits.png"),
    ]

    result_text = Text("Choisis une main pour commencer", size=18, color="white")
    score_label = Text("SCORE", size=14, weight="bold", color="white")
    score_value = Text(f"{user_score} - {comp_score}", size=28, weight="bold", color="white")
    score_bubble = Container(
        content=Container(
            content=Column(
                [
                    score_label,
                    score_value,
                ],
                alignment="center",
                horizontal_alignment="center",
                spacing=8,
            ),
            padding=10,
            bgcolor="#66000000",
            border_radius=55,
            alignment=Alignment.CENTER,
        ),
        width=160,
        height=160,
        alignment=Alignment.CENTER,
        border_radius=80,
        image=DecorationImage(
            src="assets/score.png",
            fit=BoxFit.COVER,
            alignment=Alignment.CENTER,
        ),
    )

    def get_choice_bg(choice: str) -> str:
        bg_files = {
            "Pierre": "fond_pierre.png",
            "Feuille": "fond papier.png",
            "Ciseau": "fond_ciseaux.png",
            "Puits": "fond_puits.png",
        }
        filename = bg_files.get(choice, f"fond_{choice.lower()}.png")
        path = get_asset_path(filename)
        if os.path.exists(path):
            return path
        return get_asset_path(f"{choice.lower()}.png")

    player_label = Text("Toi", size=16, weight="bold", color="white", visible=False)
    player_image = Image(src="", width=100, height=100, visible=False)
    player_bubble = Container(
        content=player_image,
        width=180,
        height=180,
        alignment=Alignment.CENTER,
        border_radius=90,
        visible=False,
    )
    computer_label = Text("Ordinateur", size=16, weight="bold", color="white", visible=False)
    computer_image = Image(src="", width=100, height=100, visible=False)
    computer_bubble = Container(
        content=computer_image,
        width=180,
        height=180,
        alignment=Alignment.CENTER,
        border_radius=90,
        visible=False,
    )
    battle_message = Text("", size=28, weight="bold", color="white", visible=False)

    def get_winner(player, computer):
        if player == computer:
            return "Égalité"

        wins = {
            "Pierre": ["Ciseau"],
            "Feuille": ["Pierre", "Puits"],
            "Ciseau": ["Feuille"],
            "Puits": ["Pierre", "Ciseau"],
        }

        if computer in wins.get(player, []):
            return "Joueur"
        return "Ordinateur"

    def play(e, choice):
        nonlocal user_score, comp_score
        computer_choice, computer_image_src = random.choice(choices)

        player_label.visible = True
        player_image.src = dict(choices)[choice]
        player_image.visible = True
        player_bubble.image = DecorationImage(
            src=get_choice_bg(choice),
            fit=BoxFit.COVER,
            alignment=Alignment.CENTER,
            color_filter=ColorFilter(color="#66000000", blend_mode=BlendMode.DARKEN),
        )
        player_bubble.visible = True
        computer_label.visible = False
        computer_image.visible = False
        computer_bubble.visible = False
        battle_message.value = "Choix en cours..."
        battle_message.visible = True
        selection_row.visible = False
        battle_row.visible = True
        play_again_button.visible = False
        page.update()

        winner = get_winner(choice, computer_choice)

        if winner == "Joueur":
            user_score += 1
            battle_message.value = "WIN"
            result = f"Tu as gagné ! {choice} bat {computer_choice}."
        elif winner == "Ordinateur":
            comp_score += 1
            battle_message.value = "LOSE"
            result = f"Tu as perdu... {computer_choice} bat {choice}."
        else:
            battle_message.value = "DRAW"
            result = f"Égalité ! Vous avez tous les deux choisi {choice}."

        score_value.value = f"{user_score} - {comp_score}"
        result_text.value = result
        computer_label.visible = True
        computer_image.src = computer_image_src
        computer_image.visible = True
        computer_bubble.image = DecorationImage(
            src=get_choice_bg(computer_choice),
            fit=BoxFit.COVER,
            alignment=Alignment.CENTER,
            color_filter=ColorFilter(color="#66000000", blend_mode=BlendMode.DARKEN),
        )
        computer_bubble.visible = True
        play_again_button.visible = True
        page.update()

    def reset(e):
        player_label.visible = False
        player_bubble.visible = False
        player_image.visible = False
        computer_label.visible = False
        computer_bubble.visible = False
        computer_image.visible = False
        battle_message.visible = False
        battle_row.visible = False
        play_again_button.visible = False
        selection_row.visible = True
        result_text.value = "Choisis une main pour recommencer"
        page.update()

    buttons = [
        Container(
            content=Image(src=image, width=100, height=100),
            width=160,
            height=160,
            border_radius=80,
            alignment=Alignment.CENTER,
            image=DecorationImage(
                src=get_choice_bg(choice),
                fit=BoxFit.COVER,
                alignment=Alignment.CENTER,
                color_filter=ColorFilter(color="#66000000", blend_mode=BlendMode.DARKEN),
            ),
            on_click=lambda e, c=choice: play(e, c),
        )
        for choice, image in choices
    ]

    selection_row = Row(buttons, alignment="center", spacing=20)
    battle_row = Row(
        [
            Column([player_label, player_bubble], alignment="center", horizontal_alignment="center"),
            Column([battle_message], alignment="center", horizontal_alignment="center"),
            Column([computer_label, computer_bubble], alignment="center", horizontal_alignment="center"),
        ],
        alignment="center",
        spacing=40,
        visible=False,
    )
    play_again_button = ElevatedButton("Rejouer", on_click=reset, visible=False, width=180)

    page.add(
        Container(
            content=Container(
                content=Column(
                    [
                        Text("Pierre Feuille Ciseau", size=30, weight="bold", color="white"),
                        Text("Clique sur une main pour jouer.", size=16, color="white"),
                        selection_row,
                        battle_row,
                        play_again_button,
                        result_text,
                        score_bubble,
                    ],
                    alignment="center",
                    horizontal_alignment="center",
                    spacing=20,
                ),
                padding=20,
                border_radius=15,
                bgcolor="#99000000",
            ),
            expand=True,
            image=DecorationImage(
                src="assets/fond.png",
                fit=BoxFit.COVER,
                alignment=Alignment.CENTER,
            ),
        )
    )
start_background_music()
app(target=main)