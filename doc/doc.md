# ZAP Projekt
## Wykrywanie krawędzi w obrazach z użyciem jednostki wektorowej SSE
Wykonał:
    Radosław Załuska


### Wstęp
Zadanie polegało na zrealizowaniu algorytmu wykrywania krawędzi w obrazach z
dodatkowym progowaniem. Całość miała być zaimplementowania na poziome asemblera
z użyciem jednostki wektorowej SSE.

### Sposób realizacji
Zadanie zostało zrealizowane jako moduł asemblera i plik c zawierający funkcję
main. Całość przetwarzania dzieli się na kilka funkcji realizujących kolejne
kroki algorytmu. Program wczytuje i działa na plikach graficznych w formacie
BMP (24 bitowym RGB).

#### Spis plików źródłowych
- main.c - moduł w C wywołujący funkcje asemblerowe
- edge.s - moduł asemblerowy

#### Spis funkcji
Kolejność wykonywania funkcji jest następująca:

1. reduce\_colors - funkcja zaimplementowania w C realiząca konwersję z obrazka
   kolorowego na odcienie szarości. Przetwarzanie przebiego po każdym pixelu
   według następującej formuły:

    $bwPixel = sourcePixel.r * 0.3 + sourcePixel.g * 0.59 + sourcePixel.b * 0x11$

    Dodaktowo funkcja dokonuje zamiany przydziłu liczb od 0 do 255 na przedział
    od -127 do 127 co będzie wykorzystywane w dalszej częci algorytmu do
    odejmowania liczb ze znakiem. Konwersja jest dokonywana poprzez równanie
    $$ ByteOut = ByteIn \mathbin{\oplus} 0x80$$

2. blur - funkcja realizowana w asemblerze przy użyciu jednostki wektorowej. Jej
   zadaniem jest dokonanie delikatnego rozmazania obrazka. Wykorzystuje do tego
   prosty 4 elementowy kernel.
    \begin{equation}
    \frac{1}{4} \begin{bmatrix}
       1 & 1 \\[0.3em]
       1 & 1
     \end{bmatrix}
     \end{equation}

     Gdzie element aktywny jest w lewym górym rogu.

3. roberts\_cross\_assembly - właściwa funkcja dokonująca wykrywania krawądzi.
   Korzysta z fultru macierzowego krzyż robertsa który składa się z dwóch
   kerneli:
    \begin{equation}
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
     \end{equation}

     Element bierzący jest w lewym górym rogu macierzy.

     Przybliżenie wypadkowej wartości krawiędzi uzyskuje się z następujących
     rachunów:
        $$tmp1 = input(x, y) - input(x+1, y+1)$$
        $$tmp2 = input(x+1, y) - input(x, y+1)$$
        $$output(x, y) = |tmp1| + |tmp2|$$
    Wartość bezwzględna zastępuje pierwiastek sumy kwadratów wartości co
    przyspiesza obliczenia.


4. thresholding - funkcji asemblerowa której zadaniem jest odrzucenie słabych
   krawędzi z obrazu i wzmocnienie tych które są wyraźnie. Wykorzystywana jest w
   niej funkcja prównywania liczb w jednostce wektorowej która jako wynik zwraca
   maski bitowe wykorzystywane do nanoszenia poprawki na progowany obraz.

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
./edge obraz-źródłowy.bmp obraz-wynikowy.bmp
```
