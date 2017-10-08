# ZAP Projekt
## Wykrywanie krawędzi w obrazach z użyciem jednostki wektorowej Intel SSE
Wykonał:

- Radosław Załuska


### Wstęp
Zadanie polegało na zrealizowaniu algorytmu wykrywania krawędzi w obrazach z
dodatkowym progowaniem wartości siły krawędzi. Całość miała być
zaimplementowania na poziome asemblera z użyciem jednostki wektorowej SSE.

Wykrywanie krawędzi w obrazach polega na obliczeniu różnic między pixelami w
bliskim sąsiedztwie. Dzięki temu uzyskujemy wartość gradientu koloru dla
poszczególnych elementów obrazu. Bardzo często samo policzenie gradientu nie
daje dobrych rezultatów ponieważ obraz może być zaszumiony lub posiadać
niewyraźne krawędzie. Aby temu zaradzić stosuje się różne techniki poprawy
działania algorytmu. Do najprostszych można zaliczyć rozmazywanie obrazu
filtrami typu blur, lub progowanie krawędzi tak aby odrzucić te słabo widoczne.

### Sposób realizacji
Zadanie zostało zrealizowane jako moduł asemblera i plik c zawierający funkcję
main. Całość przetwarzania dzieli się na kilka funkcji realizujących kolejne
kroki algorytmu. Program wczytuje i działa na plikach graficznych w formacie
BMP (24 bitowym RGB).

#### Spis plików źródłowych
- main.c - moduł w C wywołujący funkcje asemblerowe
- edge.s - moduł asemblerowy zawierający funkcje używające SSE

#### Spis funkcji
Kolejność wykonywania funkcji jest następująca:

1. reduce\_colors - funkcja zaimplementowania w C realizująca konwersję z obrazka
   kolorowego na odcienie szarości. Przetwarzanie przebiega po każdym pixelu
   według następującej formuły:

    $bwPixel = sourcePixel.red * 0.3 + sourcePixel.green * 0.59 + sourcePixel.blue * 0x11$

    Dodatkowo funkcja dokonuje zamiany przedziału liczb od 0 do 255 na przedział
    od -127 do 127 co będzie wykorzystywane w dalszej części algorytmu do
    odejmowania i porównywania liczb ze znakiem. Konwersja jest dokonywana poprzez zastosowanie
    wzoru:
    $$ ByteOut = ByteIn \mathbin{\oplus} \mathtt{0x80h}$$

    Po zastosowaniu każdym trzem wartościom RGB pixela odpowiada jedna wartość.
    Funkcja redukuje ilość przetwarzanych pixeli trzykrotnie i przyspiesza
    obliczenia. Konwersja z RGB na BW nie zmienia sposobu działania algorytmu.

2. blur - funkcja realizowana w asemblerze przy użyciu jednostki wektorowej. Jej
   zadaniem jest dokonanie delikatnego rozmycia obrazka. Wykorzystuje do tego
   prosty 4 elementowy kernel, gdzie element aktywny jest w lewym górnym rogu.
    \begin{equation}
    \frac{1}{4} \begin{bmatrix}
       1 & 1 \\[0.3em]
       1 & 1
     \end{bmatrix}
     \end{equation}


3. roberts\_cross\_assembly - właściwa funkcja dokonująca wykrywania krawędzi.
   Korzysta z filtru macierzowego krzyż robertsa który składa się z dwóch
   kerneli. Element bieżący jest w lewym górnym rogu macierzy.
   $$
    K_1 =
    \begin{bmatrix}
       1 & 0 \\[0.3em]
       0 & -1
     \end{bmatrix}
    K_2 =
    \begin{bmatrix}
       0 & 1 \\[0.3em]
       -1 & 0
     \end{bmatrix}
     $$

     Dokładna wartość wypadkowa krawędzi jest liczona ze wzoru:
     $$
     output(x,y) =
     \sqrt{(input(x,y) - input(x+1,y+1))^2 + (input(x+1,y) - input(x,y+1))^2}
     $$

     Przybliżenie wypadkowej wartości krawędzi uzyskuje się z następujących
     rachunków:
        $$tmp1 = input(x, y) - input(x+1, y+1)$$
        $$tmp2 = input(x+1, y) - input(x, y+1)$$
        $$output(x, y) = |tmp1| + |tmp2|$$
    Wartość bezwzględna zastępuje pierwiastek sumy kwadratów co przyspiesza
    obliczenia.


4. thresholding - funkcji asemblerowa której zadaniem jest odrzucenie słabych
   krawędzi z obrazu i wzmocnienie tych które są wyraźnie. Wykorzystywana jest w
   niej funkcja porównywania liczb w jednostce wektorowej która jako wynik zwraca
   maski bitowe wykorzystywane do nanoszenia poprawki na progowany obraz.

    Użycie instrukcji PBLENDVB:

    ```gnuassembler
    ; w rdi jest adres bloku 16 pixeli
    MOVDQU xmm1, [rdi]

    MOVDQA xmm14, xmm8
    PCMPGTB xmm8, xmm1; xmm8 - dolny próg
    MOVDQA xmm15, xmm8
    MOVDQA xmm0, xmm8 ; maska zostaje umieszczona w xmm0 bo PBLENDVB tam jej oczekuje

    PBLENDVB xmm1, xmm11 ; w xmm11 są bajty o wartości -128

    MOVDQA xmm8, xmm14

    MOVDQA xmm4, xmm1

    PCMPGTB xmm4, xmm9 ; xmm9 - górny próg
    MOVDQA xmm0, xmm8 ; maska zostaje umieszczona w xmm0
    PBLENDVB xmm1, xmm10 ; w xmm10 są bajty o warości 127
    ```

5. back\_colors - funkcja zaimplementowania w C. Jej zadaniem jest odwrócenie
   działania funkcji reduce\_colors.

### Sposób uruchomienia
Program był testowany na procesorze Intel(R) Celeron(R) CPU 1000M wyposażonym w
jednostkę wektorową SSE 4.2. W programie została wykorzystana instrukcja
PBLENDVB obsługiwana przez procesory z jednostką wektorową minimum Intel SSE 4.1.

#### Budowanie i uruchamianie
```bash
make
./edge obraz-źródłowy.bmp obraz-wynikowy.bmp lowerThreshold upperThreshold
```
