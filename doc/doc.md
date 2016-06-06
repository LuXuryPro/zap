# ZAP Projekt
## Wykrywanie krawędzi w obrazach z użyciem jednostki wektorowej SSE
Wykonał:

- Radosław Załuska


### Wstęp
Zadanie polegało na zrealizowaniu algorytmu wykrywania krawędzi w obrazach z
dodatkowym progowaniem. Całość miała być zaimplementowania na poziome asemblera
z użyciem jednostki wektorowej SSE.

Wykrywanie krawędzi w obrazach polega na obliczeniu różnic między pixelami w
bliskim sądiedztwie. Dzięki temu uzyskujem watrość gradientu koloru dla
poszczególnych elementów obrazu. Bardzo często samo policznie gradientu nie
daje dobrych rezultatów ponieważ obraz może być zaszumiony lub posiadać
niewyraźne krawędzie. Aby temu zaradzić stosuje się róźne techniki poprawy
działania algorytmu. Do najporstszych można zaliczyć zozmazywanie obrazu
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

1. reduce\_colors - funkcja zaimplementowania w C realiząca konwersję z obrazka
   kolorowego na odcienie szarości. Przetwarzanie przebiego po każdym pixelu
   według następującej formuły:

    $bwPixel = sourcePixel.r * 0.3 + sourcePixel.g * 0.59 + sourcePixel.b * 0x11$

    Dodaktowo funkcja dokonuje zamiany przydziłu liczb od 0 do 255 na przedział
    od -127 do 127 co będzie wykorzystywane w dalszej częci algorytmu do
    odejmowania liczb ze znakiem. Konwersja jest dokonywana poprzez zastosowanie
    wzoru:
    $$ ByteOut = ByteIn \mathbin{\oplus} \mathtt{0x80h}$$

    Po zastosowaniu każdym trzem wartościom RGB pixela odpowiada jedna wartość.
    Funkcja redukuje ilość przetwarzanych pixeli trzykrotnie i przyspiesza
    obliczenia.

2. blur - funkcja realizowana w asemblerze przy użyciu jednostki wektorowej. Jej
   zadaniem jest dokonanie delikatnego rozmazania obrazka. Wykorzystuje do tego
   prosty 4 elementowy kernel, gdzie element aktywny jest w lewym górym rogu.
    \begin{equation}
    \frac{1}{4} \begin{bmatrix}
       1 & 1 \\[0.3em]
       1 & 1
     \end{bmatrix}
     \end{equation}


3. roberts\_cross\_assembly - właściwa funkcja dokonująca wykrywania krawądzi.
   Korzysta z fultru macierzowego krzyż robertsa który składa się z dwóch
   kerneli. Element bierzący jest w lewym górym rogu macierzy.
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
     Output(x,y) =
     \sqrt{(input(x,y) - input(x+1,y+1))^2 + (input(x+1,y) - input(x,y+1))^2}
     $$

     Przybliżenie wypadkowej wartości krawiędzi uzyskuje się z następujących
     rachunów:
        $$tmp1 = input(x, y) - input(x+1, y+1)$$
        $$tmp2 = input(x+1, y) - input(x, y+1)$$
        $$output(x, y) = |tmp1| + |tmp2|$$
    Wartość bezwzględna zastępuje pierwiastek sumy kwadratów co przyspiesza
    obliczenia.


4. thresholding - funkcji asemblerowa której zadaniem jest odrzucenie słabych
   krawędzi z obrazu i wzmocnienie tych które są wyraźnie. Wykorzystywana jest w
   niej funkcja prównywania liczb w jednostce wektorowej która jako wynik zwraca
   maski bitowe wykorzystywane do nanoszenia poprawki na progowany obraz. W
   uproszczeniu działanianie funkcji jest następujące:

    ```gnuassembler
    ; przygotowanie masek do porównywania
    ; w rcx jest dolny limit progowania
    mov rax, rcx
    MOVQ xmm8, rax
    PXOR xmm3, xmm3
    PSHUFB xmm8, xmm3 ; lower limit

    ; w r8 jest górny limit progowania
    mov rax, r8
    MOVQ xmm9, rax
    mov rax, 0
    PXOR xmm3, xmm3
    PSHUFB xmm9, xmm3; upper limit
    ```
    Dla każdego bloku 16 pixeli dokonywane jest progowanie
    ```gnuassembler
    ; w rdi jest adres bloku 16 pixeli
    MOVDQU xmm1, [rdi]

    MOVDQA xmm4, xmm1

    ; porównujemy które wartści z xmm4 zawierającego dolny próg są większe
    PCMPGTB xmm4, xmm8
    ; warości większe zostały zonaczone w xmm4 jako 11111111 a mniejsze jako
    ; 00000000.

    MOVDQA xmm0, xmm4

    ;zerujemy warości mniejsze poprzez bitowy and z otrzymaną maską
    PAND xmm1, xmm4

    MOVDQA xmm4, xmm1

    ; W xmm4 są orginalne wartość. Prównujemy jest z xmm9 zawierającym górny
    ; próg
    PCMPGTB xmm4, xmm9
    ; dla wartości większych od progu w ich miejsce zostało wpisane 11111111
    ; Używany maski z jedynkami i zasępujemy nimi warości orginalne większ od
    ; górnego progu
    POR xmm1, xmm4
    ```

5. back\_colors - funkcja zaimplementowania w C. Jej zadaniem jest odwrócanie
   działania funkcji reduce\_colors.

### Sposób uruchomienia
Program był tesowany na procesorze Intel(R) Celeron(R) CPU 1000M wyposarzonym w
jednostkę wekorową SSS 4.2. Nie były wykorzystywane funkcje specyficzne dla SSE
4 jednak w celu zagawrantowania działania programu zalecane jest uruchomiene na
procesorach wyposarzonych przynajmniej w SSE4.

#### Budowanie i uruchamianie
```bash
make
./edge obraz-źródłowy.bmp obraz-wynikowy.bmp lowerThreshold upperThreshold
```
