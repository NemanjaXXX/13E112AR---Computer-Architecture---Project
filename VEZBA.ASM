! inicijalizacija simulacije
dc x.1, x.9996
dc x.0, x.9998
onkp false, x.1, x.1
onkp false, x.1, x.1
onkp true, x.1, x.1
ondma x.1, x.1
ondma x.1, x.1
ondma x.1, x.1
ondma x.1, x.1
kpreg 1.1, r0, x.1
kpreg 1.1, r1, x.2
kpreg 1.1, r2, x.3
kpreg 1.1, r3, x.4
kpreg 1.1, r4, x.5
kpreg 1.1, r5, x.6
kpreg 1.1, r6, x.7
kpreg 1.1, r7, x.8
kpreg 2.1, r0, x.9
kpreg 2.1, r1, x.a
kpreg 2.1, r2, x.b
kpreg 2.1, r3, x.c
kpreg 2.1, r4, x.d
kpreg 2.1, r5, x.e
kpreg 2.1, r6, x.f
kpreg 2.1, r7, x.10
reg pc, x.4000
reg ivtp, x.4000
reg sp, x.9000
! kraj inicijalizacije

! resenje
org x.4000
ldimm x.100,r1 ! r1=0100h
mvrir r1,ivtp ! ivtp=r1=0100h

ldimm x.3000,r1
stmem x.100,r1 ! ulaz0 3000h

ldimm x.2500,r1
stmem x.101,r1 !ulaz1 2500h 

ldimm x.1500,r1
stmem x.102,r1 !ulaz2 1500h

ldimm x.2000,r1
stmem x.103,r1!ulaz3 2000h

ldimm x.1000,r1
stmem x.104,r1!ulaz4 1000h

ldimm x.500,r1
stmem x.105,r1 !ulaz5 0500h

!Ucitavanje nizova A i B koji imaju po 8h elemenata
!Niz A od adrese 5000h i niz B od adrese 6000h

! NIZ A - UCITAVANJE - MEHANIZAM PREKIDA
!Uredjaju KP1.1 odgovara ulaz br. 5 IVT na adresi 0500h je pr. rutina
!priprema za transfer sa KP1.1 mehanizmom prekida
ldimm x.1, r4 ! fleg da li se radi o ulazu(1) ili izl.(0)
ldimm x.5000,r0     !pokazivac na pocetak niza A
ldimm x.9,r1  !br. elem.  +1 jer se prvo dec ne poc. prek. rut.
	     !pa da bi se ucitao i poslednji element
clr r2              !r2 semafor, mada je inicijalno nula
ldimm x.5,r3        !broj ulaza u KP1.1 prek. rut.
stmem x.f102, r3    ! slanje broja ulaza za KP1.1 u entry reg.
ldimm x.f,r3        !vrednost za pokretanje KP1.1, ne E
stmem x.f100,r3     !upis u kontrolni registar KP1.1

ldimm x.1,r3 !za testiranje semafora, posle ovoga ide na rutinu
wait:
      cmp r2, r3     !ceka se da se primi niz
      bneq wait      !ako je r2=r3 jos uvek prenos nije zavrsen (Z=0)

!Ucitavanje sa KP2 ispitivanjem bita spremnosti, niz B

ldimm x.6000,r0! registar r0 neka bude pokazivac na početak niza
ldimm x.9,r1! registar r1 neka bude brojac (8h)
ldimm x.5,r2 
stmem x.f200,r2!nameštanje control registra za KP2.1
               ! on se nalazi na f200h i 5 mu daje start=1 i ulaz=1

!ispitivanje bita spremnosti
ldimm x.1,r3                 !maska za proveru bita spremnosti
loop: ldmem x.f201,r4        !citanje statusnog registra KP2.1
      and r4, r4, r3         ! provera bita status
      beql loop              !ako je rez. prth. inst. 0 tj. Z=1 tada je redy=0 i ponovo se ispituje (skok za Z=1)
                      !bit spremnosti je postavljen kada se iskoci iz petlje
ldmem x.f203,r5       ! u r5 se smesta vrednost sa perif. KP2.1
stri [r0],r5          !smesta primljeni podatak u mem
inc r0                !pomeramo pokazivac na lokaciju ya sledeci upis
dec r1                 !jedan elem je upisan pa smanjimo broj elemenata
bneq loop              !ako r1 nije nula ima jos elemenata za slanje pa sve ponovo
!iskljucivanje KP2.1
clr r0
stmem x.f201,r1 !r1 je sada nula pa je redy od KP2.1 ovim nula

!------------------------B3--------------------------------------
ldimm x.5000,r1 !pokazivac na A[i]
ldimm x.6000,r2 !pokazivac na B[i]
ldimm x.0001,r3 !maska za filtriranje zadnjeg bita
ldimm x.0008, r4 !br elemenata niza

loop3: ldrid [r1]x.0,r9 !A poadatak sa adr r1 ide u r9, r1 je pokaz.
       ldrid [r2]x.0,ra !B podatak sa adr r2 ide u r10, r2 je pokaz.
       and r5, ra , r3 ! neparno r5 nije 0, parno r5=0
       beql processElem !ako je r5=0 idi na funkciju (Z=1)
       !ako nije parno docice ovde
after: inc r1
       inc r2
       dec r4 !smanjujemo brojac
       bneq loop3 ! ako nije nula radi sve ponovo (Z=0)
!nulti element niza A na 9999h, nakon procesa
       ldmem x.5000,r0
       stmem x.9999,r0
!clk=53604
       !Inicijalizacija DMA1.4
ldimm x.8,r0    !koliko podataka treba preneti u r0
stmem x.f0c4,r0 !upis u Count reg. DMA1.4
ldimm x.5000,r0 !adresa od cita DMA1.4 upisuje u mem
stmem x.f0c5,r0 !upis u izvorisni AR1 reg. DMA1.4
clr r0          !pocetna vrednost semafora je nula
stmem x.4000,r0 !odabrana slobodna lokacija x.4000 da se cuva semf.
                !mogao se koristiti neki registar
stmem x.f0c2,r0 !br ulaza za DMA1.4 je 0 a adresa 3000h pa odatle ide
                !prekidna rutina org x.3000
ldimm x.5100,r0 !odredisna adresa
stmem x.f0c6,r0 !upis u AR2 odredisni reg. ovde dugo radi
ldimm x.bf,r0 !vrednost za pokretanje DMA1.4 paketski
stmem x.f0c0,r0!upis u control reg. DMA1.4
!proveriti iznad
! ceka se da DMA1.4 zavrsi slanje
ldimm x.1, r1           ! jedinica za testiranje
                        !zbog inicijalizacije
                        !odavde skace na prekidnu rutinu
wait1: ldmem x.4000, r0 ! cita se vrednost semafora
cmp r1, r0              ! da li je semafor postao jedan
bneq wait1              ! ako nije nazad na wait1 (Z=0)
!Upis treba popraviti
!----------------------V2---------------------------------
!clk=59058 sa zakomentarisanim DMA na delu end da se lepse vidi

       jmp end !ako je zavrsio idi na halt ili sledeci zadatak
processElem:
       push r1 ! na stek adr. A[i], za slucaj poziva f-je
       jsr proces
       jmp after
end:
!zadnji zadatak V2
!pokretanje KP1.2
ldimm x.5000,r0 !pokazivac na pocetak niza A
ldimm x.9,r1 !8h+1 elemenata zbog zadnjeg
clr r2 !semafor
ldimm x.4,r3 !broj ulaza u IV za KP1.2
stmem x.f142,r3 !upisivanje u entry za KP1.2
ldimm x.f,r3 !vrednost za pokretanje KP1.2
stmem x.f140,r3!upis u ctrl reg KP1.2

ldimm x.1,r3 !za testiranje semafora, posle ovoga ide na rutinu 1000h
wait2:
      cmp r2, r3     !ceka se da se primi niz
      bneq wait2      !ako je r2=r3 jos uvek prenos nije zavrsen (Z=0)

!clk=76992
!slanje podatka sa 9999h uređaju DMA1.2 u paketskom rezimu rada
ldimm x.1,r0 !koliko podataka treba preneti u r0
stmem x.f044,r0 !upis u count reg DMA1.2
ldimm x.9999,r0 ! adresa od koje DMA1.2 cita iz mem
stmem x.f045,r0!upis u izvorisni adresni reg. AR1 DMA1.2
clr r0 !pocetna vrednost semafora je 0
stmem x.4000, r0 !odabrana slobodna lokacija za cuvanje semafora
ldimm x.1,r0!broj ulaza u IV tabelu za DMA1.2
stmem x.f042,r0!upis u entry reg. DMA1.2
ldimm x.8e, r0 !vrednost za pokretanje DMA1.2
stmem x.f040, r0 !upis u ctrl reg. DMA1.2

ldimm x.1, r1 ! jedinica za testiranje semafora
wait3: ldmem x.4000, r0 ! cita se vrednost semafora
cmp r1, r0 ! da li je semafor postao jedan
bneq wait3 ! ako nije nazad na wait1


halt


!void processElem(int* elem)
proces: !na steku su retPC pa A[i]
      pop r6 !sacuvamo retPC
      pop r7 !u r7 stavimo elem za kompl iz r1 tj. adresu njegovu
      push r7 ! sada imamo dve iste adrese na steku i u r7
      ldrid [r7]x.0,r7 !sa adrese r7 upise sada podatak u r7!
      not r7 ! komplementiramo rez je u r7
      pop r8 !u r8 je adresa niza a gde treba smestiti rezultat, stek je prazan
      stri [r8],r7
      push r6
rts




org x.500 !prekidna rutina KP1.1, nalazi se u memoriji od adr. 500h
!Sada r0=5000h pokazivac
!r1=9h broj elemenata!
!prvi slobodan za koriscenje je r5
ldimm x.1,r5
cmp r4,r5 !da li se radi ulaz ili izlaz
bneq izlaz !radi se izlaz (Z=0)

!ulaz
!prijem elementa
dec r1 !smanjujemo brojac za 1 elem.
beql iskljuci !svi elem. su primljeni, iskljucujem periferiju (Z=1)
ldmem x.f103, r6 !citanje jednog elem iz data reg. od KP1.1
stri [r0],r6
inc r0
jmp kraj 

izlaz:
	dec r1 !smanjujemo brojac
	beql iskljuci ! Z=1

iskljuci:
	stmem x.f100, r1 ! u r1 je nula pa se koristi za iskljucivanje KP1
	ldimm x.1, r2    ! postavlja se semafor, prenos zavrsen
kraj: 			!nakon svakog elementa novi prekid
	rti !Ovim je niz od 8h elemenata ucitan sa KP1.1!

!prekidna rutina za KP1.2, ne znam zasto samo jednom ulazi
org x.1000
!Sada je r0=5000 i r1=9h elemenata
!prenos elementa
dec r1
beql iskljuci2 ! svi su prekopirani iskljuci KP1.2(skace za Z=1)
ldmem x.f143,r9 ! pristup data registru KP1.2 samo da bi se generisao prekid
ldrid [r0]x.0,r6 !U r6 element niza A
stmem x.f143, r6
inc r0
jmp back

iskljuci2:
	stmem x.f140,r5 !r5=0 gasimo KP1.2 u ctrl se upise 0
	ldimm x.1,r2 !postavljanje semafora da je prenos gotov
back:
	rti !izlaz iz prekidne rutine




org x.2500 !odavde krece prek. rut. za DMA1.2
push r0 ! koristi se r0 pa se njegova vrednost cuva na steku
ldimm x.1, r0 ! jedinica za semafor
stmem x.4000, r0 ! postavljanje semafora
clr r0 ! nula za kontrolni registar DMA za iskljucivanje
stmem x.f040, r0 ! upis u kontrolni registar
pop r0 ! vracanje stare vrednosti r0
rti ! povratak iz prekidne rutine



!prekidna rutina za DMA1.4
org x.3000
push r0          ! koristi se r0 pa se njegova vrednost cuva na steku
ldimm x.1, r0    ! jedinica za semafor
stmem x.4000, r0 ! postavljanje semafora
clr r0           ! nula za kontrolni registar DMA za iskljucivanje
stmem x.f0c0, r0 ! upis u kontrolni registar
pop r0           ! vracanje stare vrednosti r0
rti              ! povratak iz prekidne rutine



