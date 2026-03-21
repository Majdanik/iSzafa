# iSzafa 

**iSzafa** to innowacyjna aplikacja na iOS zbudowana w technologii SwiftUI. Pozwala użytkownikom na digitalizację swojej garderoby, inteligentne wycinanie ubrań z tła za pomocą sztucznej inteligencji (Core ML / Vision) oraz kreatywne łączenie elementów w gotowe stylizacje (outfity).

---

## Główne funkcje

* **Skaner Ubrań (AI Background Removal):** Wbudowane narzędzie wykorzystujące `VNGenerateForegroundInstanceMaskRequest`, które automatycznie izoluje ubranie od tła na podstawie wybranego zdjęcia z galerii.
* **Wirtualna Szafa (SwiftData):** Lokalna baza danych przechowująca Twoje ubrania z podziałem na kategorie (Czapki, Okulary, Góra, Dół, Buty, Akcesoria). Elementy są zapisywane w formie zoptymalizowanych danych za pomocą `@Attribute(.externalStorage)`.
* **Kreator Stylizacji (Canvas):** Interaktywne płótno, na którym możesz:
  * Przewijać ubrania w odpowiednich slotach (np. zmieniać koszulki nad spodniami).
  * Dowolnie przesuwać i skalować elementy (`DragGesture`, `MagnificationGesture`).
* **Obsługa Akcesoriów:** Dedykowana "szuflada", z której możesz wyciągać nieskończoną ilość dodatków i obracać je na płótnie (`RotationGesture`).
* **Zapisywanie i Udostępnianie:**
  Gotowy outfit można wyeksportować w wysokiej jakości (`ImageRenderer`) i udostępnić na zewnątrz dzięki `ShareLink`.

---

## Technologie

Projekt został zbudowany z wykorzystaniem nowoczesnego stosu technologicznego Apple:

* **Framework UI:** SwiftUI
* **Baza danych:** SwiftData (z użyciem `@Model` i `@Environment(\.modelContext)`)
* **Przetwarzanie obrazu:** Vision Framework (AI Masking), CoreImage (CIFilterBuiltins)
* **Obsługa multimediów:** PhotosUI (`PhotosPicker`)

---

## Struktura i Nawigacja

Aplikacja opiera się na głównej nawigacji typu `TabView`, dzieląc interfejs na dwa kluczowe moduły:

1. **`WardrobeView` (Szafa):** Miejsce do zarządzania kolekcją. Zawiera interfejs do skanowania (wyboru z rolki aparatu), kategoryzowania dodawanych ubrań oraz siatkę (`LazyVGrid`) z możliwością usuwania wpisów.
2. **`CreatorView` (Kreator):** Główny silnik aplikacji. Składa się z nałożonych na siebie slotów (`CategorySlotView`), które odpowiadają fizycznej anatomii (nakrycie głowy na górze, buty na dole). Posiada również zaawansowaną obsługę wolnostojących akcesoriów (`AccessoryDraggableView`).

---

## Uruchomienie projektu

1. Sklonuj to repozytorium na swój komputer.
2. Otwórz projekt w środowisku **Xcode 15** (lub nowszym) – wymagane ze względu na użycie biblioteki `SwiftData`.
3. Wybierz symulator (np. iPhone 15 Pro) lub podłącz własne urządzenie.
4. Naciśnij `Cmd + R` (Run).

*Uwaga: Funkcja "Wyciskanie z tła" wykorzystująca AI działa najwydajniej na fizycznych urządzeniach z układem Neural Engine (procesory serii A Bionic).*

---

## Plany na przyszłość 

Projekt **iSzafa** stale się rozwija, a moje główne cele na najbliższy czas to:

* **Dostępność w App Store:** Trwają intensywne prace nad przygotowaniem aplikacji do oficjalnej publikacji w sklepie Apple. Już wkrótce każdy będzie mógł pobrać iSzafę bezpośrednio na swojego iPhone'a!
* **Dedykowana strona internetowa:** Równolegle buduję oficjalną stronę projektu. Będzie to centralne miejsce z informacjami o funkcjach, aktualizacjach oraz poradnikami, jak wyciągnąć z aplikacji 100% możliwości. (Link pojawi się tutaj wkrótce).

