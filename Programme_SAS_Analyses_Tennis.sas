/*******************************PROJET SAS*******************************/
/*Avant de commencer, il faut nettoyer le dossier WORK*/
proc datasets library=work kill;
run;
quit;

/* Importation de données */
DATA PLAYERS ; 
INFILE "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/Players.csv" DELIMITER=","
FIRSTOBS=2 DSD ; 
INPUT player_id name_first $ name_last $ hand $ birthdate country $ gender $ ;
RUN ; 

DATA MATCHES ; 
INFILE "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/Matches.csv" DELIMITER = ","
FIRSTOBS=2 DSD ; 
INPUT tourney_id $ tourney_name $ surface $ draw_size $ tourney_level $ tourney_date $ match_num winner_id winner_seed $
 winner_entry $ winner_name $ winner_hand $ winner_ht winner_ioc $ winner_age loser_id loser_seed $ loser_entry $ 
 loser_name $ loser_hand $ loser_ht loser_ioc $ loser_age score $ best round $ minutes w_ace w_df w_svpt w_1stIn
 w_1stWon w_2ndWon w_SvGms w_bpSaved w_bpFaced l_ace l_df l_svpt l_1stIn l_1stWon l_2ndWon l_SvGms l_bpSaved 
 l_bpFaced winner_rank winner_rank_points loser_rank loser_rank_points league $;
RUN ; 


/* --- Analyse des variables --- */
PROC CONTENTS DATA = PLAYERS ; 
RUN ; 

PROC CONTENTS DATA = MATCHES ; 
RUN ;  

/* --- Affichage tableaux --- */

ods pdf file="/home/u63770182/projet_sas/image_pdf/premieres_obs.pdf";

PROC PRINT DATA=PLAYERS (OBS=10);
RUN;

PROC PRINT DATA=MATCHES (OBS=10);
RUN;

ods pdf close;

/* --- Analyse de valeurs manquantes --- */
/* Variables numériques*/
PROC MEANS DATA = PLAYERS NMISS ; 
RUN ; 

PROC MEANS DATA = MATCHES NMISS; 
RUN ; 

* ---> les deux tables contiennent des valeur manquantes;

* ---> dire qu'on traitera les valeur manquantes plus tard sur les variables qu'on utilisera;

/* --- Test merge---*/
/*PROC SQL;
CREATE TABLE DATA AS
SELECT *
FROM MATCHES M
LEFT JOIN PLAYERS P
ON M.winner_id = P.player_id;
QUIT;

PROC SQL; 
SELECT UNIQUE(TOURNEY_NAME), SURFACE 
FROM MATCHES ;
RUN; */

*---> dire que les merges n'ont pas été concluant et qu'on a préferé se concentrer sur la table MATCHES qui contenait toutes les infos pour notre analyse;

/* --- Recodage de la table ---*/

data NEW_MATCHES;
    set MATCHES;

    player_id = winner_id;
    player_seed = winner_seed;
    player_entry = winner_entry;
    player_name = winner_name;
    player_hand = winner_hand;
    player_ht = winner_ht;
    player_ioc = winner_ioc;
    player_age = winner_age;
    ace = w_ace;
    df = w_df;
    svpt = w_svpt;
    _1stIn = w_1stIn;
    _1stWon = w_1stWon;
    _2ndWon = w_2ndWon;
    _SvGms = w_SvGms;
    bpSaved = w_bpSaved;
    bpFaced = w_bpFaced;
    player_rank = winner_rank;
    player_rank_points = winner_rank_points;
    is_winner = 1; 
    output;

    player_id = loser_id;
    player_seed = loser_seed;
    player_entry = loser_entry;
    player_name = loser_name;
    player_hand = loser_hand;
    player_ht = loser_ht;
	player_ioc = loser_ioc;
    player_age = loser_age;
    ace = l_ace;
    df = l_df;
    svpt = l_svpt;
    _1stIn = l_1stIn;
    _1stWon = l_1stWon;
    _2ndWon = l_2ndWon;
    _SvGms = l_SvGms;
    bpSaved = l_bpSaved;
    bpFaced = l_bpFaced;
    player_rank = loser_rank;
    player_rank_points = loser_rank_points;
    is_winner = 0; 
    output;


    drop winner_id winner_seed winner_entry winner_name 
    winner_hand winner_ht winner_ioc winner_age w_ace w_df 
    w_svpt w_1stIn w_1stWon w_2ndWon w_SvGms w_bpSaved
    winner_rank winner_rank_points;
    drop loser_id loser_seed loser_entry loser_name 
    loser_hand loser_ht loser_ioc loser_age l_ace l_df 
    l_svpt l_1stIn l_1stWon l_2ndWon l_SvGms l_bpSaved
    loser_rank loser_rank_points;
run;
* ---> se recodage permet ...;
proc print data= NEW_MATCHES (obs=10);
run;

/* Ajout de la variable gender*/

DATA NEW_MATCHES;
    LENGTH gender $ 10; /* Définit une longueur maximale de 10 caractères pour 'gender' */
    SET NEW_MATCHES;
    IF league = "atp" THEN gender = "Male";
    ELSE IF league = "wta" THEN gender = "Female";
    ELSE gender = "Unknown"; 
RUN;


/* Table des perdants*/
DATA MATCHES_LOSER;
    SET NEW_MATCHES;
    WHERE is_winner = 0;
RUN;


/* Table des gagnants*/
DATA MATCHES_WINNER;
    SET NEW_MATCHES;
    WHERE is_winner = 1;
RUN;


/* Table des femmes*/
DATA MATCHES_F;
    SET NEW_MATCHES;
    WHERE gender = "Female";
RUN;

/* Table des hommes*/
DATA MATCHES_H;
    SET NEW_MATCHES;
    WHERE gender = "Male";
RUN;

/*distribution des sexes*/
ods pdf file="/home/u63770182/projet_sas/image_pdf/distribution_genre.pdf";

PROC FREQ DATA=NEW_MATCHES;
    TABLES gender / MISSING;
    TITLE "Distribution des genres";
RUN;

ods pdf close;

*---> Un peu plus de femmes que d'homme dans la table cependnat 
on s'appercoit par la suite que les données des femmes ont beaucoup 
plus de valeaur manquantes et de moins bonne qualité que celles des hommes;

/*----------------------------------------------------------------------------------------*/
/*I. Facteurs liés aux joueurs
	1. Analyse des caractéristiques physiques et de leur impact
	
	Question principale : Les caractéristiques physiques influencent-elles les performances des joueurs ?

Variables clés :
- Taille (winner_ht, loser_ht)
- Main dominante (winner_hand, loser_hand)
- Âge (winner_age, loser_age)*/


/*---------------------------------------------------------------------------*/
/*------------------------ Analyse des variables : --------------------------*/
/*---------------------------------------------------------------------------*/

* ------Variables de taille :
;

/* Vérifier les valeurs manquantes et aberrantes*/

%MACRO DisplayMissingPercentage(data, var);
    PROC MEANS DATA= &data N NMISS MIN MAX MEAN STD;
        VAR &var; 
        OUTPUT OUT=Stats_&var NMISS=NumMissing N=NumNoMissing;
    RUN;

    DATA Stats_&var._With_Percent;
        SET Stats_&var;
        PercentMissing = (NumMissing / (NumMissing + NumNoMissing)) * 100;
        VariableName = "&var"; 
    RUN;

    PROC PRINT DATA=Stats_&var._With_Percent;
        VAR VariableName NumMissing PercentMissing;
        TITLE "Tableau des Valeurs Manquantes et de Leur Pourcentage pour &var";
    RUN;
%MEND DisplayMissingPercentage;

%DisplayMissingPercentage(NEW_MATCHES, player_ht);

*---> moitié des variables sont manquantes à traiter;

* Regarder les variable manquante par sexe:;

%MACRO AnalyzeMissingValues(data=, classVar=, var=);
    /* Calcul des valeurs manquantes et non manquantes */
    PROC MEANS DATA=&data N NMISS;
        CLASS &classVar;
        VAR &var;
        OUTPUT OUT=Stats_By_&classVar NMISS=NumMissing N=NumNoMissing;
        TITLE "Valeurs manquantes de &var par &classVar";
    RUN;

    /* Calcul du pourcentage de valeurs manquantes */
    DATA Stats_With_Percent_&classVar;
        SET Stats_By_&classVar;
        IF _TYPE_ = 1 THEN DO; /* _TYPE_ = 1 signifie regroupé par &classVar */
            PercentMissing = (NumMissing / (NumMissing + NumNoMissing)) * 100;
        END;
    RUN;

    /* Affichage des résultats */
    PROC PRINT DATA=Stats_With_Percent_&classVar NOOBS;
        TITLE "Pourcentage de valeurs manquantes de &var par &classVar";
        VAR &classVar NumMissing NumNoMissing PercentMissing;
    RUN;
%MEND AnalyzeMissingValues;

%AnalyzeMissingValues(data=NEW_MATCHES, classVar=gender, var=player_ht);

*---> malgres une présence légèrement plus eleve pour les femmes :
	- 80 % de variables manquantes pour les femmes
	- 16 % chez les hommes
	=> On peut donc supposer que l'analyse des hommes sera plus concluante que celle des femmes

/* Traitement des valeurs manquantes */

* ---> pour traiter nos valeur manquantes on a testé plusiquers idées :
	- on a chercher a voir si certaines tailles de joueur n'etait pas presente sur d'autre ligne du meme joueur : mais cela n'a pas été concluant
	- on aurait pu tronquer par la moyenne ou la mediane maos cela aurait selon nous biaisé notre analyse
	  En effet, au vu du nombre de valeur manquantes cela allait un peu fausser nos résultats.
	  De plus au vu de la quantité de données il nous a semblé suffisant de ne garder que les données de qualités pour avoir une analyse précise.;


*------ Variable âge;

/* Vérifier les valeurs manquantes et aberrantes*/

* Valeur manquantes : ;
%DisplayMissingPercentage(NEW_MATCHES, player_age);

* Porportions valeurs négative (abberantes) : ;
PROC SQL;
    SELECT 
        COUNT(*) AS Total_Observations,
        SUM(CASE WHEN player_age < 0 THEN 1 ELSE 0 END) AS Negative_Values,
        (CALCULATED Negative_Values / CALCULATED Total_Observations) * 100 AS Proportion_Negative FORMAT=8.2
    FROM NEW_MATCHES;
QUIT;

*---> beaucoup de valeurs manquante à traiter. Plusieurs idée de traitement ont été abordées:
	- remplacer les ages manquants par des ages des joueurs trouvés dans d'autres lignes. 
		Problème : selon les matches les joueurs n'avaient pas le meme age 
	- mettre la moyenne focerait légèrement notre analyse nousavons décidé de la supprimer
*---> variable négatives : incoherence
	- On a supprimé ces variables car ne pouvant pas etre ramené à 0;

* Regarder les variable manquante par sexe:;

%AnalyzeMissingValues(data=NEW_MATCHES, classVar=gender, var=player_age);

*---> toujours une moins bonne qualité pour les donnée des femmes

*------ Variables main dominante ;
/* Vérifier les valeurs manquantes et aberrantes*/
PROC FREQ DATA=NEW_MATCHES;
    TABLES player_hand / MISSING;
    TITLE "Fréquences des mains dominantes des joueurs";
RUN;
* ---> tres peu de valeur manquantes (moins d'1%):
	- mettre les valeurs manquantes en "U" (inconnu) mais cela aurait légèrement pu modifier les resultats
	- on supprime les valeurs manquantes ;


/*--- Traitement des variables---*/

DATA MATCHES_CLEAN;
    SET NEW_MATCHES;
    /* Filtrer les lignes avec des valeurs valides pour player_ht, player_age et player_hand */
    IF NOT MISSING(player_ht) AND
       NOT MISSING(player_age) AND player_age >= 0 AND
       player_hand IN ("L", "R", "U") AND NOT MISSING(player_hand);
RUN;

/* Vérification après nettoyage */
PROC FREQ DATA=MATCHES_CLEAN;
    TABLES player_hand / MISSING;
    TITLE "Vérification des valeurs de main dominante après nettoyage";
RUN;

PROC MEANS DATA=MATCHES_CLEAN N NMISS MIN MAX MEAN STD P25 P50 P75;
    VAR player_age player_ht;
    TITLE "Vérification des âges et tailles après traitement des valeurs manquantes et aberrantes";
RUN;

/*---------------------------------------------------------------------------*/
/*------------------------ Analyse descriptive : ----------------------------*/
/*---------------------------------------------------------------------------*/

/* --- Variable player_ht : ---*/

/* Histrogrammes : */
* Histogrammes de la variable player_ht;
PROC SGPLOT DATA=MATCHES_CLEAN;
    HISTOGRAM player_ht / BINWIDTH=5 FILLATTRS=(COLOR=BLUE);
    TITLE "Distribution de la taille";
RUN;

* Histogrammes de la variable player_ht (comparaison gagnant/perdant);
PROC SGPLOT DATA=MATCHES_CLEAN;
    HISTOGRAM player_ht / GROUP=is_winner BINWIDTH=5 TRANSPARENCY=0.5 FILLATTRS=(COLOR=BLUE);
    KEYLEGEND / TITLE="Gagnants et Perdants";
    TITLE "Distribution des tailles des joueurs (gagnants vs perdants)";
RUN;

* Histogrammes de la variable player_ht (comparaison femme/homme);
PROC SGPLOT DATA=MATCHES_CLEAN;
    HISTOGRAM player_ht / GROUP=gender BINWIDTH=5 TRANSPARENCY=0.5 FILLATTRS=(COLOR=BLUE);
    KEYLEGEND / TITLE="Femmes et Hommes";
    TITLE "Distribution des tailles des joueurs (femmes vs hommes)";
RUN;

*---> distribustion entre gagnant et perdant quasiment identiques :
	- taille ne semble pas réellement influencer le resultat du match;

*===> Au vu de notre analyse precedante il serait interessant de separer les hommes des femmes:;

/* Classification :*/

* ---> Classifier player_ht:
	- Petit : Taille inférieure au 25e percentile (Q1) — soit moins de 178 cm.
	- Moyen : Taille entre le 25e percentile (Q1) et le 75e percentile (Q3) — soit entre 178 cm et 183 cm.
	- Grand : Taille supérieure au 75e percentile (Q3) — soit plus de 183 cm.
* ---> Classifier player_age :
	- Jeune : Moins de 25 ans 
	- Adulte : De 25 à 40 ans.
	- Senior : Plus de 40 ans.;

data MATCHES_CLEAN_CLAS;
    set MATCHES_CLEAN;
    
    /* Classification de player_ht */
    if player_ht < 178 then ht_category = "Petit";
    else if player_ht >= 178 and player_ht <= 183 then ht_category = "Moyen";
    else if player_ht > 183 then ht_category = "Grand";

    /* Classification de player_age */
    if player_age < 25 then age_category = "Jeune";
    else if player_age >= 25 and player_age <= 40 then age_category = "Adulte";
    else if player_age > 40 then age_category = "Senior";
RUN;


* Proportions d'hommes et de femmes dans player_ht ;
PROC FREQ DATA=MATCHES_CLEAN_CLAS;
    TABLES gender*ht_category / OUT=Freq_HT_CATEGORY NOPERCENT NOCUM;
    TITLE "Proportions d'hommes et de femmes dans ht_category (taille)";
RUN;

* Proportions d'hommes et de femmes dans player_ht en fonction de si on a gagné ou perdu;
PROC FREQ DATA=MATCHES_CLEAN_CLAS;
    TABLES is_winner*gender*ht_category / NOPERCENT NOCUM;
    TITLE "Proportions d'hommes et de femmes dans ht_category (taille) en fonction des victoires et des défaites";
RUN;

/* --- Variable player_age : ---*/

/* Histogramme age*/

* Histogramme de la variable age : ;
PROC SGPLOT DATA=MATCHES_CLEAN;
    HISTOGRAM player_age / BINWIDTH=2 FILLATTRS=(COLOR=BLUE);
    TITLE "Distribution de l'âge";
RUN;

* Histogramme de la variable age (comparaison gagnant/perdant) : ;
PROC SGPLOT DATA=MATCHES_CLEAN;
    HISTOGRAM player_age / GROUP=is_winner BINWIDTH=2 TRANSPARENCY=0.5 FILLATTRS=(COLOR=BLUE);
    KEYLEGEND / TITLE="Gagnants et Perdants";
    TITLE "Distribution de l'âge des joueurs (gagnants vs perdants)";
RUN;

/* Proportions : */

* Proportions d'hommes et de femmes dans player_age;
PROC FREQ DATA=MATCHES_CLEAN_CLAS;
    TABLES gender*age_category / NOPERCENT NOCUM;
    TITLE "Proportions d'hommes et de femmes dans player_age (âge)";
RUN;

* Proportions d'hommes et de femmes dans player_age en fonction de si on a gagné ou perdu;
PROC FREQ DATA=MATCHES_CLEAN_CLAS;
    TABLES gender*is_winner*age_category / NOPERCENT NOCUM;
    TITLE "Proportions d'hommes et de femmes dans player_age (âge) en fonction des victoires et des défaites";
RUN;
* ---> chez les femmes les proportions de gagnants en fonctions des catégories d'âge
sont toujours plus elevés, sauf dans la ctégories sénior oùil y a une proportion de perdant plus importante
* ---> chez les hommes les proportions de gagnants en fonctions des catégories d'âge
sont toujours plus elevés
* ---> général:
	- on constate que la base est constituée principalement d'adultes ou de jeunes
	- on peut pas réellement faire de conclusion sur une eventuelle victoire ou defaite

/* --- Variable player_hand : ---*/
* Proportions d'hommes et de femmes dans player_hand;
PROC FREQ DATA=MATCHES_CLEAN;
    TABLES gender*player_hand / NOPERCENT NOCUM;
    TITLE "Proportions d'hommes et de femmes dans player_hand (main dominante)";
RUN;

* Proportions d'hommes et de femmes dans player_hand en fonction de si on a gagné ou perdu;
PROC FREQ DATA=MATCHES_CLEAN_CLAS;
    TABLES gender*is_winner*player_hand / NOPERCENT NOCUM;
    TITLE "Proportions d'hommes et de femmes dans player_hand (main dominante) en fonction des victoires et des défaites";
RUN;
* ---> plus de droitiers que de gaucher sont présents dans la base mais logique
Ainsi les conclusions sont biaisés;

* Diagramme en barres de la distribution des mains dominantes;
PROC SGPLOT DATA=MATCHES_CLEAN;
    VBAR player_hand / FILLATTRS=(COLOR=BLUE);
    TITLE "Distribution des mains dominantes des joueurs";
RUN;

* Diagramme en barres de la distribution des mains dominantes pour les hommes;
PROC SGPLOT DATA=MATCHES_CLEAN;
    WHERE gender = "Male"; /* Filtrer les hommes */
    VBAR player_hand / FILLATTRS=(COLOR=BLUE);
    TITLE "Distribution des mains dominantes des hommes (gagnants vs perdants)";
RUN;

/* --------------------------------------------------------------------------------------------*/
/* --- Autre méthode : ---*/
/* ===> malgres toutes ces analyses on constate que nous n'arrivons pas réellement à ressortir
		des caractéristiques physiques qui pourraient réellement influencer le fait d'être "gagnant"
		ou "perdant".
		On a donc eu l'idée de plutot comparer les résultats de chaque match :
		- pour chaque match noter si le gagnant était plus grand que le perdant
		- si le gagnant était plus agée ou plus jeune
		- si le gagnant était droitié ou gaucher
		Afin de plus réellement constater si les caractéristique physiques influence le résultats des matchs.*/

DATA MATCHES_UPDATED;
	LENGTH age_comparison $12 height_comparison $12 dominant_hand_comparison $15;
    SET MATCHES;
    /* Comparaison de l'âge */
    IF NOT MISSING(winner_age) AND NOT MISSING(loser_age) THEN DO;
        IF winner_age > loser_age THEN age_comparison = "Plus âgé"; 
        ELSE IF winner_age < loser_age THEN age_comparison = "Plus jeune"; 
        ELSE age_comparison = "Égal";
    END;

    /* Comparaison de la taille */
    IF NOT MISSING(winner_ht) AND NOT MISSING(loser_ht) THEN DO;
        IF winner_ht > loser_ht THEN height_comparison = "Plus grand";
        ELSE IF winner_ht < loser_ht THEN height_comparison = "Plus petit";
        ELSE height_comparison = "Égal";
    END;

    /* Vérification de la main dominante */
    IF winner_hand = "R" THEN dominant_hand_comparison = "Droitier";
    ELSE dominant_hand_comparison = "Non droitier";

RUN;


PROC PRINT DATA=MATCHES_UPDATED (OBS=10);
RUN;

* Comparaisons : ;
PROC FREQ DATA=MATCHES_UPDATED NOPRINT;
    TABLES age_comparison / OUT=FreqAgeComparison;
    TABLES height_comparison / OUT=FreqHeightComparison;
    TABLES dominant_hand_comparison / OUT=FreqDominantHandComparison;
RUN;

proc print data=FreqDominantHandComparison;
run;

* Graphique pour l'âge: ; 
%MACRO VbarGraph(dataset, var);
    PROC SGPLOT DATA=&dataset;
        VBAR &var / RESPONSE=COUNT DATALABEL GROUP=&var 
                    COLORMODEL=(CXFF5733 CX33FF57 CX5733FF); /* Liste des couleurs */
        TITLE "Proportion des gagnants par comparaison de &var";
        XAXIS LABEL="Comparaison de &var";
        YAXIS LABEL="Fréquence";
    RUN;
%MEND VbarGraph;

ods pdf file="/home/u63770182/projet_sas/image_pdf/prop_gagnant_age.pdf";
%VbarGraph(FreqAgeComparison, age_comparison);
ods pdf close;


*---> pas de réelles conclusions possibles meme si les personnes plus agées donc 
	plus expérimentées ont en moyennes plus de victoires ;


* Graphique pour la taille: ; 

%VbarGraph(FreqHeightComparison, height_comparison);

* ---> - beaucoup de variables inconnues
	   - un personne plus grande que sont adversaire aura une légère tendance a plus gagner;
	   
* Graphique pour la main dominante : ; 

%VbarGraph(FreqDominantHandComparison, dominant_hand_comparison);

* ---> etre droitier semble favorisé le fait de remporter un match. Cependant ce resultat est 
	"normal" puisqu'on a une proportion de personne droitière plus importatnte dans la table;


* SURFACE ; 

* Nb matches par surface;
PROC FREQ DATA = MATCHES  ; 
TABLES SURFACE/ OUT = NB_MATCH_SURFACE ; 
BY LEAGUE ; 
RUN ;
ODS PDF FILE= "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/NB_MATCH_SURFACE_LIGUE.pdf";
PROC SGPLOT DATA = NB_MATCH_SURFACE  ;
TITLE "Nombre de matches par surface selon la ligue"; 
VBAR SURFACE / RESPONSE= COUNT GROUP = LEAGUE GROUPDISPLAY=CLUSTER  ; 
WHERE SURFACE <> 'nan';
RUN ; 
ODS PDF CLOSE ; 

* Nb manquantes de surface par tourney level; 
PROC SORT DATA = MATCHES ; 
BY LEAGUE TOURNEY_NAME ;
RUN ; 
PROC FREQ DATA = MATCHES  ; 
TABLES SURFACE*TOURNEY_LEVEL / OUT = NB_MATCH_NAN_SURFACE ;
BY LEAGUE;
WHERE SURFACE = 'nan' ; 
RUN ;
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/NB_NA_MATCH_SURFACE_LIGUE.pdf" ; 
PROC SGPLOT DATA = NB_MATCH_NAN_SURFACE ; 
TITLE 'Valeurs manquantes par Type de tournoi et league'; 
VBAR LEAGUE / RESPONSE = COUNT GROUP = TOURNEY_LEVEL GROUPDISPLAY=CLUSTER ; 
RUN ; 
ODS PDF CLOSE ;

* Reperage des valeurs manquantes par tournoi selon la surface. 
  On peut dire que parmi les types de tournois seulement 2 concentrent 
  les NA pour les Hommes et 4 pour les Femmes. ; 

* NB De matchs par type de surface pour chaque type de tournoi. ; 
PROC SORT DATA = MATCHES ; 
BY LEAGUE TOURNEY_LEVEL ; 
RUN ; 
PROC FREQ DATA = MATCHES  ; 
TABLES SURFACE / PLOTS=FREQPLOT OUT = NB_MATCH_SURFACE_TOURNEY; 
WHERE SURFACE <> 'nan'; 
BY LEAGUE TOURNEY_LEVEL ; 
RUN; 
PROC SGPANEL DATA = NB_MATCH_SURFACE_TOURNEY ; 
PANELBY TOURNEY_LEVEL ; 
VBAR SURFACE / RESPONSE = COUNT GROUP = SURFACE GROUPDISPLAY= CLUSTER ; 
RUN ;

PROC TRANSPOSE DATA = NB_MATCH_SURFACE_TOURNEY  OUT = SURFACES_TRANSPOSED_1;
BY LEAGUE TOURNEY_LEVEL  ;
ID     SURFACE ; 
RUN ; 
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/NB_MATCH_SURFACE_LIGUE_TOURNOI.pdf" 
STYLE = Pearl;  
PROC REPORT DATA = SURFACES_TRANSPOSED_1 SPLIT = '@' STYLE = PEARL; 
COLUMNS LEAGUE _NAME_ TOURNEY_LEVEL CARPET CLAY GRASS HARD INDOORS ; 
BY LEAGUE ;
DEFINE LEAGUE / NOPRINT 'Ligue' ; 
DEFINE TOURNEY_LEVEL / GROUP   'Niveau@du@Tournoi' ; 
WHERE _NAME_ = 'COUNT' ; 
DEFINE _NAME_ / NOPRINT ; 
DEFINE INDOORS / NOZERO ; 
RUN ; 
ODS PDF CLOSE ; 

PROC FORMAT ; 
VALUE DECENNIE 
	LOW - 1959 = 'A_50s'
	1960 - 1969 = 'A_60s'
	1970 - 1979 = 'A_70s'
	1980 - 1989 = 'A_80s'
	1990 - 1999 = 'A_90s'
	2000 - 2010 = 'A_00s'
	2010 - HIGH = 'A_10s'; 
VALUE CATAGE 
	7 - 18  = 'JUNIOR'
	18 - 34 = 'SENIOR'
	34 - HIGH = 'SENIOR PLUS'; 
VALUE DECENNIE_LABEL 
	LOW - 1959 = '50s'
	1960 - 1969 = '60s'
	1970 - 1979 = '70s'
	1980 - 1989 = '80s'
	1990 - 1999 = '90s'
	2000 - 2010 = '00s'
	2010 - HIGH = '10s'; 
RUN ; 

DATA MATCHES_YEAR ; 
SET MATCHES (KEEP = LEAGUE SURFACE TOURNEY_LEVEL TOURNEY_DATE MINUTES WINNER_HAND LOSER_HAND WINNER_HT LOSER_HT BEST WINNER_IOC WINNER_AGE LOSER_AGE WINNER_IOC) ; 
YEAR = INT(SCAN(TOURNEY_DATE,1,'-')); 
RUN ;

* NB MATCHES PAR SURFACE YEAR ;  
PROC SORT DATA = MATCHES_YEAR ; 
BY LEAGUE YEAR ;
FORMAT YEAR DECENNIE. ;  
RUN ; 
PROC FREQ DATA = MATCHES_YEAR ; 
FORMAT YEAR   ;  
TABLES SURFACE/ PLOTS=FREQPLOT OUT = MATCH_SURFACE ; 
BY LEAGUE YEAR; 
WHERE SURFACE <> 'nan'; 
RUN ;
PROC TRANSPOSE DATA = MATCH_SURFACE OUT = EVOLUTION_SURFACES ; 
ID SURFACE; 
VAR COUNT ; 
BY LEAGUE YEAR SURFACE; 
RUN ; 
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/EVOL_SURF_ATP.pdf" ; 
PROC SGPLOT DATA = EVOLUTION_SURFACES  ;
XAXIS TYPE= DISCRETE ; 
SERIES X = YEAR  Y = CLAY ;
SERIES X = YEAR  Y = CARPET ;
SERIES X = YEAR  Y = GRASS ; 
SERIES X = YEAR  Y = HARD ;
WHERE LEAGUE = 'atp';
XAXIS LABEL = 'Année' ;
YAXIS LABEL  = "Nb d'occurrences" ; 
TITLE "Evolution de NB de match par surface ATP" ;
RUN ; 
ODS PDF CLOSE ; 

ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/EVOL_SURF_WTA.pdf" ; 
TITLE "Evolution de NB de match par surface WTA"; 
PROC SGPLOT DATA = EVOLUTION_SURFACES  ;
XAXIS TYPE= DISCRETE ; 
SERIES X = YEAR  Y = CLAY ;
SERIES X = YEAR  Y = CARPET ;
SERIES X = YEAR  Y = GRASS ; 
SERIES X = YEAR  Y = HARD ;
SERIES X = YEAR  Y = INDOORS ;
WHERE LEAGUE = 'wta' ;
XAXIS LABEL = 'Année' ;
YAXIS LABEL  = "Nb d'occurrences" ; 
RUN ; 
TITLE ; 
ODS PDF CLOSE ; 

PROC FREQ DATA = MATCHES_YEAR ; 
FORMAT YEAR DECENNIE.; 
TABLES TOURNEY_LEVEL*SURFACE/ PLOTS=FREQPLOT OUT = MATCH_LEVEL ; 
BY LEAGUE YEAR; 
RUN ; 
PROC SGPANEL DATA = MATCH_LEVEL ; 
PANELBY YEAR ; 
VBAR SURFACE / RESPONSE= COUNT GROUP = TOURNEY_LEVEL GROUPDISPLAY=CLUSTER GROUPORDER=DESCENDING ; 
WHERE SURFACE <> 'nan' AND LEAGUE = 'atp';
RUN ; 
PROC SGPANEL DATA = MATCH_LEVEL ; 
PANELBY YEAR ; 
VBAR SURFACE / RESPONSE= COUNT GROUP = TOURNEY_LEVEL GROUPDISPLAY=CLUSTER GROUPORDER=DESCENDING ; 
WHERE SURFACE <> 'nan' AND LEAGUE <> 'atp';
RUN ; 
PROC SORT DATA = MATCH_LEVEL ; 
BY LEAGUE TOURNEY_LEVEL SURFACE YEAR ;
RUN ; 
PROC TRANSPOSE DATA = MATCH_LEVEL OUT = MATCH_SURFACE_LEAGUE; 
ID YEAR  ; 
BY LEAGUE TOURNEY_LEVEL SURFACE ; 
RUN ; 
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/EVOL_SURF_TOURNOI_LEAGUE.pdf" ; 
PROC REPORT DATA = MATCH_SURFACE_LEAGUE (DROP= _LABEL_) SPLIT='@' ; 
COLUMNS _ALL_; 
BY LEAGUE ; 
DEFINE LEAGUE / NOPRINT ; 
DEFINE  TOURNEY_LEVEL / GROUP 'Niveau@du@tournoi'; 
DEFINE SURFACE / GROUP 'Surface' ; 
DEFINE  A_50S / NOZERO 'Années@50'  ;
DEFINE  A_60S / 'Années@60' ;
DEFINE  A_70S /  'Années@70';
DEFINE  A_80S /  'Années@80';
DEFINE  A_90S /  'Années@90';
DEFINE  A_00S /'Années@00' ;
DEFINE  A_10S / 'Années@10'; 
DEFINE _NAME_ /NOPRINT;
WHERE _NAME_ = 'COUNT' AND SURFACE <> 'nan';
RUN ; 
ODS PDF CLOSE ; 

* Distribution par type de surface pour chaque type de tournoi à
  chaque décennie. ; 

PROC FREQ DATA = MATCHES_YEAR ; 
FORMAT YEAR DECENNIE.; 
TABLES SURFACE*YEAR/OUT = SURFACE_YEAR; 
BY LEAGUE ; 
RUN ;
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/EVOL_SURF_TOURNOI_GRAPH.pdf"; 
PROC SGPLOT DATA = SURFACE_YEAR ; 
FORMAT YEAR DECENNIE_LABEL. ; 
VBAR SURFACE / RESPONSE = COUNT GROUP = YEAR GROUPDISPLAY=cluster ;
WHERE SURFACE <> 'nan'; 
LABEL YEAR = 'Année' ;
RUN ;
ODS PDF CLOSE ; 


* Distribution générale des surface par décennie. ;  
PROC SORT DATA = MATCHES_YEAR ; 
BY LEAGUE TOURNEY_LEVEL ; 
RUN ; 
PROC FREQ DATA = MATCHES_YEAR ;
TABLES SURFACE*WINNER_HAND / OUT = WINNER_HAND_SURFACE; 
BY LEAGUE TOURNEY_LEVEL;
WHERE WINNER_HAND <> 'nan' AND TOURNEY_LEVEL <> 'nan'; 
RUN;
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/LRU_ATP_TOURNOI_SURFACE.pdf" ; 
PROC SGPANEL DATA = WINNER_HAND_SURFACE ;
PANELBY TOURNEY_LEVEL ;
VBAR WINNER_HAND /RESPONSE = COUNT GROUP = SURFACE GROUPDISPLAY=CLUSTER ; 
WHERE LEAGUE <> 'wta' AND SURFACE <> 'nan';
RUN ; 
ODS PDF CLOSE ; 
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/LRU_WTA_TOURNOI_SURFACE.pdf"; 
PROC SGPANEL DATA = WINNER_HAND_SURFACE ;
PANELBY TOURNEY_LEVEL ;
VBAR WINNER_HAND /RESPONSE = COUNT GROUP = SURFACE GROUPDISPLAY=CLUSTER ; 
WHERE LEAGUE <> 'atp' AND SURFACE <> 'nan';
RUN ;   
ODS PDF CLOSE ; 

PROC SORT DATA = WINNER_HAND_SURFACE ; 
BY LEAGUE TOURNEY_LEVEL SURFACE WINNER_HAND ; 
RUN ; 
PROC TRANSPOSE DATA = WINNER_HAND_SURFACE OUT = T_WINNER_HAND_SURFACE ;
ID WINNER_HAND ; 
BY LEAGUE TOURNEY_LEVEL SURFACE ; 
RUN ; 
DATA T_WINNER_HAND_SURFACE ; 
SET T_WINNER_HAND_SURFACE ; 
RATIO = L/R ; 
RUN;  
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/WINNER_HAND_PROP_IIbis.pdf" ; 
PROC REPORT DATA = T_WINNER_HAND_SURFACE SPLIT ='@';
COLUMNS LEAGUE TOURNEY_LEVEL SURFACE L R U RATIO ;
BY LEAGUE ; 
WHERE SURFACE <> 'nan' AND _NAME_ = 'COUNT'; 
DEFINE LEAGUE / NOPRINT ; 
DEFINE L / 'Gaucher';
DEFINE U / 'Indefini'; 
DEFINE R / 'Droitier'; 
DEFINE TOURNEY_LEVEL / GROUP 'Niveau@du@tournoi'; 
RUN ; 
ODS PDF CLOSE ; 

PROC FREQ DATA = MATCHES ; 
TABLE WINNER_HAND LOSER_HAND ; 
RUN ; 
PROC SORT DATA = MATCHES_YEAR ; 
BY LEAGUE TOURNEY_LEVEL LOSER_HAND ; 
RUN ; 
PROC FREQ DATA = MATCHES_YEAR ;
TABLES SURFACE*LOSER_HAND / OUT = LOSER_HAND_SURFACE; 
BY LEAGUE TOURNEY_LEVEL;
WHERE LOSER_HAND <> 'nan' AND TOURNEY_LEVEL <> 'nan'; 
RUN;
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/LRU_ATP_TOURNOI_SURFACE_LOSER.pdf" ;
PROC SGPANEL DATA = LOSER_HAND_SURFACE ;
PANELBY TOURNEY_LEVEL ;
VBAR LOSER_HAND /RESPONSE = COUNT GROUP = SURFACE GROUPDISPLAY=CLUSTER ; 
WHERE LEAGUE <> 'wta' AND SURFACE <> 'nan';
RUN ; 
ODS PDF CLOSE ; 
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/LRU_WTA_TOURNOI_SURFACE_LSOER.pdf"; 
PROC SGPANEL DATA = LOSER_HAND_SURFACE ;
PANELBY TOURNEY_LEVEL ;
VBAR LOSER_HAND /RESPONSE = COUNT GROUP = SURFACE GROUPDISPLAY=CLUSTER ; 
WHERE LEAGUE <> 'atp' AND SURFACE <> 'nan';
RUN ;   
ODS PDF CLOSE ; 

PROC SORT DATA = LOSER_HAND_SURFACE ; 
BY LEAGUE TOURNEY_LEVEL SURFACE LOSER_HAND ; 
RUN ; 
PROC TRANSPOSE DATA = LOSER_HAND_SURFACE OUT = T_LOSER_HAND_SURFACE ;
ID LOSER_HAND ; 
BY LEAGUE TOURNEY_LEVEL SURFACE ; 
RUN ; 
DATA T_LOSER_HAND_SURFACE ; 
SET T_LOSER_HAND_SURFACE ; 
RATIO = L/R ; 
RUN;  
* Fréquences main perdante;
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/LOSER_HAND_PROP_II.pdf" ; 
PROC REPORT DATA = T_LOSER_HAND_SURFACE SPLIT ='@';
COLUMNS LEAGUE TOURNEY_LEVEL SURFACE L R U RATIO ;
BY LEAGUE ; 
WHERE SURFACE <> 'nan' AND _NAME_ = 'COUNT'; 
DEFINE LEAGUE / NOPRINT ; 
DEFINE L / 'Gauchier';
DEFINE U / 'Indefini'; 
DEFINE R / 'Droitier'; 
DEFINE TOURNEY_LEVEL / GROUP 'Niveau@du@tournoi'; 
RUN ; 
ODS PDF CLOSE ; 
* MATCH POUR TYPES DE MAIN DU GAGNANT ET PERDANT ;
DATA  MATCHES_COMBAT ; 
SET MATCHES (KEEP = LEAGUE TOURNEY_DATE TOURNEY_LEVEL  SURFACE WINNER_HAND LOSER_HAND BEST) ; 
IF (WINNER_HAND = 'R') AND (LOSER_HAND = "L") THEN DOMINANT = 'RIGHT'; 
IF WINNER_HAND = LOSER_HAND  THEN DOMINANT = 'EQUALS'; 
IF (WINNER_HAND = 'L') AND (LOSER_HAND = 'R') THEN DOMINANT = 'LEFT' ; 
IF (WINNER_HAND = 'U') OR (LOSER_HAND = 'U') THEN DOMINANT = 'UNDEFINED'; 
RUN ; 
ODS PDF FILE =  "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/COMBAT_HAND.pdf"  ; 
PROC FREQ DATA = MATCHES_COMBAT  ; 
TABLE  SURFACE*DOMINANT / NOCUM NOCOL NOPERCENT ; 
BY LEAGUE ; 
WHERE SURFACE <> 'nan' ; 
RUN ;
ODS PDF CLOSE ;  

PROC FREQ DATA = MATCHES_COMBAT ; 
TABLE SURFACE*DOMINANT*BEST ; 
BY LEAGUE ; 
WHERE SURFACE <> 'nan' ; 
RUN ; 
* ; 
DATA MATCHES_YEAR_HT ; 
SET MATCHES_YEAR ; 
IF WINNER_HT > LOSER_HT THEN W_HT_L = 'W Grand' ; 
IF WINNER_HT < LOSER_HT  THEN W_HT_L = 'W Petit'; 
IF WINNER_HT = LOSER_HT  THEN W_HT_L = 'Equal'; 
WHERE WINNER_HT <> . OR LOSER_HT <> . ;
RUN ; 
PROC FREQ DATA = MATCHES_YEAR_HT ;  
FORMAT YEAR DECENNIE_LABEL. ; 
TABLE YEAR*SURFACE*W_HT_L / NOCUM NOCOL NOPERCENT OUT = MATCHES_YEAR_HT_TREATED;
BY LEAGUE ;
RUN; 
ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/HEIGHT_ATP_B.pdf" ; 
PROC SGPLOT DATA = MATCHES_YEAR_HT_TREATED ; 
VBAR W_HT_L / RESPONSE = COUNT GROUP = YEAR GROUPDISPLAY=CLUSTER;
WHERE LEAGUE ='atp' ; 
XAXIS LABEL = 'Comparaison Taille Gagnants par rapport aux Perdants ATP '; 
RUN ; 
ODS PDF CLOSE ; 

ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/HEIGHT_WTA_B.pdf" ; 
PROC SGPLOT DATA = MATCHES_YEAR_HT_TREATED ; 
VBAR W_HT_L / RESPONSE = COUNT GROUP = YEAR GROUPDISPLAY=CLUSTER;
WHERE LEAGUE ='wta'; 
XAXIS LABEL = 'Comparaison Taille Gagnants par rapport aux Perdants WTA '; 
RUN ; 
ODS PDF CLOSE ; 

ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/HEIGHT_ATP_SURFAC.pdf" ;
PROC SGPLOT DATA = MATCHES_YEAR_HT_TREATED ; 
VBAR W_HT_L / RESPONSE = COUNT GROUP = SURFACE GROUPDISPLAY=CLUSTER;
WHERE LEAGUE ='atp'  AND SURFACE <> 'nan'; 
XAXIS LABEL = 'Comparaison Taille Gagnants par rapport aux Perdants ATP '; 
RUN ;
ODS PDF CLOSE ;  

ODS PDF FILE = "/home/u63916302/my_shared_file_links/u63916302/projet_sas_tide_shared/HEIGHT_WTA_SURFACE.pdf" ;
PROC SGPLOT DATA = MATCHES_YEAR_HT_TREATED ; 
VBAR W_HT_L / RESPONSE = COUNT GROUP = SURFACE GROUPDISPLAY=CLUSTER;
WHERE LEAGUE ='wta' AND SURFACE <> 'nan'; 
XAXIS LABEL = 'Comparaison Taille Gagnants par rapport aux Perdants WTA '; 
RUN ; 
ODS PDF CLOSE ; 



/*----------------------------------------------------------------------------------------*/

/*III/ 3. Impact des rounds sur les performances*/
/*Question principale : Comment les performances varient-elles selon les rounds (finale, demi-finale, etc.) ?
Variables clés :
- round
- Durée (minutes), aces (w_ace), doubles fautes (w_df), breaks sauvés (w_bpSaved)*/

/*---------------------------------------------------------------------------*/
/*------------------------ Analyse des variables : --------------------------*/
/*---------------------------------------------------------------------------*/

/* Vérifier les valeurs manquantes et aberrantes*/

PROC MEANS DATA=NEW_MATCHES N NMISS MIN MAX MEAN STD;
    VAR minutes ace df bpSaved; 
    OUTPUT OUT=Stats NMISS=NumMissing N=NumNoMissing;
RUN;

%DisplayMissingPercentage(NEW_MATCHES, minutes);
%DisplayMissingPercentage(NEW_MATCHES, ace);
%DisplayMissingPercentage(NEW_MATCHES, df);
%DisplayMissingPercentage(NEW_MATCHES, bpSaved);
* ---> pourcentage de valeure manquantes pour toutes ces variables >65%.
	   Cela est surement due au fait que ces variables releves des informations tres précises
	   Pour traiter au mieux ces valeurs manquantes, il nous a paru plus judicieux de les supprimer
	   (pourcentage de valeurs manquantes élevées et quantité de données élevé);

/* Suppression des valeurs (car trop de variables manquantes pour emputer par moyenne ou mediane) ou négatives*/

DATA NEW_MATCHES_CLEAN2;
    SET NEW_MATCHES;
    IF missing(minutes) OR missing(ace) OR missing(df) OR missing(bpSaved) OR bpSaved < 0 THEN DELETE;
RUN;

PROC MEANS DATA=NEW_MATCHES_CLEAN2 N NMISS MIN MAX MEAN STD;
    VAR minutes ace df bpSaved; 
    OUTPUT OUT=Stats NMISS=NumMissing N=NumNoMissing;
RUN;

/*---------------------------------------------------------------------------*/
/*------------------------ Analyse descriptive : ----------------------------*/
/*---------------------------------------------------------------------------*/

/* On reordonne la variable round 
Variable round : 
	- ER : "Early Round" (tour préliminaire)
	- BR : "Bracket Round" (tour de tableau éliminatoire)
	- R128 :"Round of 128" (tour des 128 participants)
	- R64 : "Round of 64" (tour des 64 participants)
	- R32 : "Round of 32" (tour des 32 participants)
	- R16 : "Round of 16" (16ème de finale)
	- Q4 : 4e tour de qualification 
	- QF : "Quarter Final"
	- SF : "Semi Final" (demi-finale)
	- RR : "Round Robin" (tournoi à la ronde), où chaque compétiteur affronte tous les autres dans un format de compétition.
	- F : "Finale" */

	

/* Calcul des statistiques combinées par round */
PROC MEANS DATA=NEW_MATCHES NOPRINT;
    CLASS round is_winner; /* Groupement par round et rôle */
    VAR minutes ace df bpSaved; /* Variables de performance */
    OUTPUT OUT=StatsCombined MEAN=mean_minutes mean_ace mean_df mean_bpSaved;
RUN;

PROC PRINT DATA=StatsCombined;
    TITLE "Statistiques Moyennes par Round (Gagnants et Perdants)";
RUN;

*---> supprimer la class "Q4" de la variable round car a une frequence de 2 et 
mean_minutes mean_ace mean_df mean_bpSaved sont vides;

DATA NEW_MATCHES;
    SET NEW_MATCHES;
    IF round = "Q4" THEN DELETE;
RUN;

/* Vérification que la classe "Q4" a été supprimée */
PROC FREQ DATA=NEW_MATCHES;
    TABLE round;
    TITLE "Distribution de la Variable Round après Suppression de la Classe Q4";
RUN;

/* Table des perdants*/
DATA MATCHES_LOSER;
    SET NEW_MATCHES;
    WHERE is_winner = 0;
RUN;


/* Table des gagnants*/
DATA MATCHES_WINNER;
    SET NEW_MATCHES;
    WHERE is_winner = 1;
RUN;

/* Calcul des performances des gagnants par round */
PROC MEANS DATA=MATCHES_WINNER NOPRINT;
    CLASS round; 
    VAR minutes ace df bpSaved; 
    OUTPUT OUT=StatsByRoundWinner MEAN=mean_minutes mean_ace mean_df mean_bpSaved;
RUN;

PROC PRINT DATA=StatsByRoundWinner;
    TITLE "Statistiques Moyennes des Gagnants par Round";
RUN;


/* Calcul des performances des perdants par round */
PROC MEANS DATA=MATCHES_LOSER NOPRINT;
    CLASS round; 
    VAR minutes ace df bpSaved; 
    OUTPUT OUT=StatsByRoundLoser MEAN=mean_minutes mean_ace mean_df mean_bpSaved;
RUN;

PROC PRINT DATA=StatsByRoundLoser;
    TITLE "Statistiques Moyennes des Perdants par Round";
RUN;

/* Fusionner les statistiques des gagnants et des perdants */
DATA StatsByRoundCombined;
    MERGE StatsByRoundWinner (RENAME=(mean_ace=mean_ace_w mean_df=mean_df_w mean_bpSaved=mean_bpSaved_w))
          StatsByRoundLoser (RENAME=(mean_ace=mean_ace_l mean_df=mean_df_l mean_bpSaved=mean_bpSaved_l));
    BY round;
RUN;

PROC PRINT DATA=StatsByRoundCombined;
    TITLE "Statistiques Moyennes des Gagnants et Perdants par Round";
RUN;


/* Graphique en barres pour la moyenne des aces */

PROC TRANSPOSE DATA = STATSBYROUNDCOMBINED (KEEP = ROUND MEAN_ACE_W MEAN_ACE_L) OUT = GRAPH_ACE; 
BY ROUND ;
RUN ; 
PROC SGPLOT DATA= GRAPH_ACE; 
VBAR ROUND / RESPONSE = COL1 GROUP= _NAME_ GROUPDISPLAY=cluster;
TITLE "Moyenne des Aces par Round (Gagnants vs Perdants)";
RUN ; 

/* Graphique en barres pour la moyenne des doubles fautes */

PROC TRANSPOSE DATA = STATSBYROUNDCOMBINED (KEEP = ROUND MEAN_DF_W MEAN_DF_L) OUT = GRAPH_DF; 
BY ROUND ;
RUN ; 
PROC SGPLOT DATA= GRAPH_DF; 
VBAR ROUND / RESPONSE = COL1 GROUP= _NAME_ GROUPDISPLAY=cluster;
TITLE "Moyenne des oubles Fautes par Round (Gagnants vs Perdants)";
RUN ; 

/* Graphique en barres pour la moyenne des breaks sauvés */

PROC TRANSPOSE DATA = STATSBYROUNDCOMBINED (KEEP = ROUND MEAN_BPSAVED_W MEAN_BPSAVED_L) OUT = GRAPH_BREAKS_SAUVES; 
BY ROUND ;
RUN ; 
PROC SGPLOT DATA= GRAPH_BREAKS_SAUVES; 
VBAR ROUND / RESPONSE = COL1 GROUP= _NAME_ GROUPDISPLAY=cluster;
TITLE "Moyenne des Breaks Sauvés par Round (Gagnants vs Perdants)";
RUN ; 

/*******************************PROJET SAS PARTIE B *******************************/

/*Code ayant généré les Sections 3.2 à 3.4*/

/*Avant de commencer, il faut nettoyer le dossier WORK*/

proc datasets library=work kill;
run;
quit;

/*  Importation des bases de données : players.csv et matches.csv
    Il faut définir l'emplacement des fichiers dans la macro-variable project_path,
    et le reste du processus s'exécute automatiquement.
*/

%let project_path = /home/u63956311/SAS_PROJET;
%let players_file = Players.csv;
%let matches_file = Matches.csv;

/*pour importer Players.csv*/

proc import datafile="&project_path/&players_file"
    out=work.players
    dbms=csv
    replace;
    delimiter=',';
    getnames=yes;
    guessingrows=max;
run;

/*les 10 premières observations*/

proc print data=work.players(obs=10);
run;

/*pour importer Matches.csv*/

proc import datafile="&project_path/&matches_file"
    out=work.matches
    dbms=csv
    replace;
    delimiter=',';
    getnames=yes;
    guessingrows=max;
run;

/*les 10 premières observations*/

proc print data=work.matches (OBS=10); 
run;

/* 	Les valeurs manquantes (NA) dans nos tables.  
	Pour information : PROC MEANS permet de visualiser les NA uniquement  
	pour les variables de type numérique*/

proc means data=work.matches n nmiss min max mean median;
run;

proc means data=work.players n nmiss min max mean median;
run;

/*proc means data=work.players nmiss n;
run;

proc means data=work.matches nmiss n;
run;

/* 	Selon l'étude menée et les variables dont nous avons besoin, 
	il faudra adapter la méthode de gestion des NA. 
	Par ailleurs, de nombreuses valeurs manquantes (NA) sont présentes dans nos données, 
	et dans certains cas, l'échantillon risque de ne pas être 
	suffisamment représentatif de l'ensemble de la population si le ratio de NA est trop élevé*/


/*	Caractéristiques des joueurs qui influent sur les victoires/defaites
	Exploration des caractéristiques des joueurs = Une piste intéressante 
	à explorer réside dans le développement d’analyses statistiques 
	en utilisant des méthodes adaptées.*/
	
proc means data=work.matches n nmiss min max std mean median;
	var winner_age loser_age winner_ht loser_ht winner_rank loser_rank;
run;

/*matches_winner*/

data matches_winner;
   set work.matches;
   keep 
   winner_id winner_seed winner_entry winner_name 
   winner_hand winner_ht winner_ioc;
run;

/*matches_loser*/

data matches_loser;
   set work.matches;
   keep 
   loser_id loser_seed loser_entry loser_name 
   loser_hand loser_ht loser_ioc;
run;

/*ou*/

data new_matches_table;
    set work.matches;

    player_id = winner_id;
    player_seed = winner_seed;
    player_entry = winner_entry;
    player_name = winner_name;
    player_hand = winner_hand;
    player_ht = winner_ht;
    player_ioc = winner_ioc;
    player_age = winner_age;
    player_rank = winner_rank;
    player_rank_points = winner_rank_points;
    is_winner = 1; /*1 pour winner*/
    output;

    player_id = loser_id;
    player_seed = loser_seed;
    player_entry = loser_entry;
    player_name = loser_name;
    player_hand = loser_hand;
    player_ht = loser_ht;
    player_ioc = loser_ioc;
    player_age = loser_age;
    player_rank = loser_rank;
    player_rank_points = loser_rank_points;
    is_winner = 0; /*0 pour loser*/
    output;


    drop winner_id winner_seed winner_entry winner_name 
    winner_hand winner_ht winner_ioc winner_age 
    winner_rank winner_rank_points;
    drop loser_id loser_seed loser_entry loser_name 
    loser_hand loser_ht loser_ioc loser_age 
    loser_rank loser_rank_points;
run;

/*  Il faut créer une table avec les codes CIO actuels
	Ici, nous avons récupéré les pays qui apparaissent deux fois 
	(ou dont le code ISO a changé au fil du temps).*/
data new_matches;
    set new_matches_table;
    if player_ioc = "LEB" then player_ioc = "LBN"; /* Liban */
    else if player_ioc = "LVA" then player_ioc = "LAT"; /* Lettonie */
    else if player_ioc = "LBY" then player_ioc = "LBA"; /* Libye */
    else if player_ioc = "BRU" then player_ioc = "BRN"; /* Brunei */
    else if player_ioc = "LIB" then player_ioc = "LBN"; /* Liban (variante de LEB) */
    else if player_ioc = "SIN" then player_ioc = "SGP"; /* Singapour */
    else if player_ioc = "FRG" then player_ioc = "GER"; /* Allemagne de l'Ouest -> Allemagne */
    else if player_ioc = "RHO" then player_ioc = "ZIM"; /* Rhodésie -> Zimbabwe */
    else if player_ioc = "ECA" then player_ioc = "CAF"; /* Afrique centrale */
    else if player_ioc = "TTO" then player_ioc = "TRI"; /* Trinité-et-Tobago */
    else if player_ioc = "CAR" then player_ioc = "CAF"; /* République centrafricaine */
    else if player_ioc = "SYC" then player_ioc = "SEY"; /* Seychelles */
run;

proc means data=work.new_matches n nmiss min max mean median;
run;

proc print data=new_matches (obs=10);
run;

proc ttest data=new_matches;
   class is_winner;
   var player_age player_ht;
run;

proc corr data=new_matches;
   var player_rank player_rank_points;
   with is_winner;
run;

/***********************MAP CONSTRUCTION***********************/
/*  Nombre de victoires par pays
    Il faudra par ailleurs ramener ce nombre au total de matchs
    pour que cela ait du sens dans l'interprétation, puisqu'il peut
    y avoir des pays avec beaucoup de joueurs et donc beaucoup de matchs*/

proc freq data=work.new_matches;
    tables player_ioc / missing; 
run;
/*player_ioc		"nan" = > Frequency: 571	 Percent: 0.08	
					DONC c'est négligeable
					l'option de tout simplement supprimer les NA est adoptée*/

/*pour visualiser les lignes absentes où le pays manque*/

data a;
set work.new_matches;
where player_ioc = 'nan';
run;

/*pour exporter*/
*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/rapport_freq_NA_pays.html";
proc freq data=work.new_matches;
    tables player_ioc / missing;
run;
*ods html close;

proc means data=work.new_matches n nmiss;
    var is_winner;
run;

/*is_winner			PAS DE NA pour cette variable*/

/*pour supprimer les nan*/

data map_matches;
	set work.new_matches;
	keep player_ioc is_winner;
run;

/*pour garder seulement les lignes où ni player_ioc ni is_winner ne sont manquants*/

data map_matches_clean;
    set work.new_matches;
    if not (player_ioc = "nan" or player_ioc = "" or is_winner = . or is_winner = .n);
    keep player_ioc is_winner;
run;

/*vérification des NA*/

proc means data=map_matches_clean n nmiss;
    var is_winner;
run;

proc freq data=map_matches_clean;
    tables player_ioc / missing;
run;

/*  On somme le nombre de cas où un joueur a gagné, selon 
    le pays auquel il appartient*/

proc sql;
    create table resultats_par_pays as
    select 
        player_ioc as country,
        sum(is_winner) as total_wins,
        sum(1 - is_winner) as total_losses
    from work.map_matches_clean
    group by player_ioc;
quit;

/*  On calcule le nombre de matchs en sommant les victoires et les défaites,
    pour ensuite calculer un ratio qui sera le nombre moyen de matchs gagnés*/

proc sql;
    create table resultats_par_pays_2 as
    select 
        player_ioc as country,
        sum(is_winner) as total_wins,
        sum(1 - is_winner) as total_losses,
        calculated total_wins + calculated total_losses as total_matches,
        calculated total_wins / calculated total_matches * 100 as ratio_win format=8.2
    from work.map_matches_clean
    group by player_ioc;
quit;

/*exporter le top 10 en terme de nb de victoires*/
/*on trie les données par total_wins en ordre décroissant*/
proc sort data=work.resultats_par_pays out=aa;
    by descending total_wins;
run;

/*ajoute une colonne 'Rang'*/
data aa_with_rang;
    set aa;
    Rang = _N_; 
run;

/*pour affficher les 10 premières lignes avec la colonne 'Rang'*/
*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/wins_by_country.html";
proc print data=aa_with_rang (obs=20) label noobs;
    label Rang = 'Rang';
    label total_wins = 'Nombre de victoires';
    label total_losses = 'Nombre de défaites';
    label country = 'Pays';
run;
*ods html close;

/*exporter le top 10 en terme de ratio de victoires*/
/*on trie les données par total_wins en ordre décroissant*/
proc sort data=work.resultats_par_pays_2 out=aaa;
    by descending ratio_win;
run;

/*ajoute une colonne 'Rang'*/
data aa_with_rang_2;
    set aaa;
    Rang = _N_;
    where total_matches>1000;
run;

/*pour affficher les 10 premières lignes avec la colonne 'Rang'*/
*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/ratio_by_country.html";
proc print data=aa_with_rang_2 (obs=20) label noobs;
    label Rang = 'Rang';
    label total_matches = 'Nombre de matchs';
    label total_wins = 'Nombre de victoires';
    label total_losses = 'Nombre de défaites';
    label country = 'Pays';
    label ratio_win = 'Taux de victoires';
run;
*ods html close;

/*  Il a fallu récupérer le code ISO à 2 chiffres de chaque pays,
    puisque ce que nous avons est le code CIO (code sportif des pays).
    Donc, on procède au recodage en recherchant pour chaque 
    code CIO son équivalent en code ISO*/ 

data iso_mapping;
    input CIO_Code $ ISO_Code $;
    datalines;
AFG AF
ALB AL
ALG DZ
AND AD
ANG AO
ANT AG
ARG AR
ARM AM
ARU AW
AUS AU
AUT AT
AZE AZ
AHO CW
BAH BS
BAN BD
BAR BB
BEL BE
BEN BJ
BER BM
BHU BT
BIH BA
BIZ BZ
BLR BY
BOL BO
BOT BW
BRA BR
BRN BN
BUL BG
BUR BF
CAF CF
CAM KH
CAN CA
CAY KY
CGO CG
CHA TD
CHI CL
CHN CN
CIV CI
CMR CM
COD CD
COK CK
COL CO
COM KM
CPV CV
CRC CR
CRO HR
CUB CU
CYP CY
CZE CZ
DEN DK
DJI DJ
DMA DM
DOM DO
ECU EC
EGY EG
ESA SV
ESP ES
EST EE
ETH ET
FIJ FJ
FIN FI
FRA FR
FSM FM
GAB GA
GAM GM
GBR GB
GBS GW
GEO GE
GER DE
GHA GH
GRE GR
GRN GD
GUA GT
GUI GN
GUM GU
GUY GY
HAI HT
HKG HK
HON HN
HUN HU
INA ID
IND IN
IRI IR
IRL IE
IRQ IQ
ISL IS
ISR IL
ISV VI
ITA IT
IVB VG
JAM JM
JOR JO
JPN JP
KAZ KZ
KEN KE
KGZ KG
KIR KI
KOR KR
KOS XK
KSA SA
KUW KW
LAO LA
LAT LV
LBN LB
LBR LR
LCA LC
LES LS
LIE LI
LTU LT
LUX LU
MAD MG
MAR MA
MAS MY
MAW MW
MDA MD
MDV MV
MEX MX
MGL MN
MKD MK
MLI ML
MLT MT
MNE ME
MON MC
MOZ MZ
MRI MU
MTN MR
MYA MM
NAM NA
NCA NI
NED NL
NEP NP
NGR NG
NIG NE
NOR NO
NRU NR
NZL NZ
OMA OM
PAK PK
PAN PA
PAR PY
PER PE
PHI PH
PLE PS
PLW PW
PNG PG
POL PL
POR PT
PRK KP
PUR PR
QAT QA
ROU RO
RSA ZA
RUS RU
RWA RW
SAM WS
SEN SN
SEY SC
SGP SG
SKN KN
SLE SL
SLO SI
SMR SM
SOL SB
SOM SO
SRB RS
SRI LK
SSD SS
STP ST
SUD SD
SUR SR
SVK SK
SUI CH
SWE SE
SWZ SZ
SYR SY
TAN TZ
TGA TO
THA TH
TJK TJ
TKM TM
TLS TL
TOG TG
TPE TW
TRI TT
TUN TN
TUR TR
TUV TV
UGA UG
UKR UA
UAE AE
URU UY
USA US
UZB UZ
VAN VU
VEN VE
VIE VN
VIN VC
YEM YE
ZAM ZM
ZIM ZW
MHL MH
LBA LY
;
run;

proc print data = work.resultats_par_pays_2;
run;

/*  On fusionne la table contenant les codes (ISO et CIO)
    avec la table des résultats par pays : nombre de victoires, 
    de défaites, total de matchs et le ratio victoires/total*/

proc sql;
    create table merged_resultats as
    select 
        b.CIO_Code as country_code,
        b.ISO_Code as isoalpha2,
        a.country,
        a.total_wins,
        a.total_losses,
        a.total_matches,
        a.ratio_win
    from iso_mapping as b
    right join resultats_par_pays_2 as a
    on a.country = b.CIO_Code;
quit;

data merged_resultats_clean;
    set merged_resultats;
    if not missing(isoalpha2) and isoalpha2 ne '';
run;

/*  On trie d'abord le dataset contenant les coordonnées utiles 
    à la construction de la carte. 
    Cette dernière est réalisée grâce à la table world dans la librairie 
    mapsgfk. */
/*  On s'assure que mapsgfk.world est triée par id*/

proc sort data=mapsgfk.world out=world_map;
   by id;
run;

/*  L'id sera, dans notre table, le code ISO à deux chiffres.
    On trie également cette table et 
    on suppose que isoalpha2 correspond au même code que 'id' dans mapsgfk.world*/

data merged_resultats_clean_id;
    set merged_resultats_clean;
    id = isoalpha2; 
run;

proc sort data=merged_resultats_clean_id;
   by id;
run;

/* 	- On fusionne ici les données cartographiques (world_map) 
   	  avec les données de victoires (merged_resultats_clean_id).
   	- On garde toutes les observations de world_map (pour avoir tous les pays de la carte).
   	- On n'ajoute que la colonne total_wins de merged_resultats_clean_id.
   	- Et selon cette colonne, la couleur va différer.
   	- Si un pays n'est pas dans merged_resultats_clean_id, total_wins sera manquant.
   	ATTENTION : on n'a pas tous les pays dans notre base, et certains pays 
   	n'existent plus aujourd'hui (les données datent du 22-12-1949)*/

data world_map_merged;
    merge world_map(in=wm) merged_resultats_clean_id(in=mr keep=id 
    total_wins 
    total_losses
    ratio_win);
    by id;
    if wm; 
run;

/*  Par défaut, la couleur est bleue et peu visible pour marquer les 
    différences. 
    C'est pourquoi on définit une palette pour gagner en clarté
    Chaque carte est exportée en pdf (meilleure qualité versus hmtl)*/
*ods pdf file="/home/u63956311/SAS_PROJET/sorties_ods/map_total_wins.pdf";  
goptions reset=all;
title "Nombre total de victoires par pays";

pattern1 v=msolid c=cxB22222;  /*couleur la plus claire*/
pattern2 v=msolid c=cxFF4500;
pattern3 v=msolid c=cxFFA500;
pattern4 v=msolid c=cxFFD700;
pattern5 v=msolid c=cxADFF2F;
pattern6 v=msolid c=cx32CD32; /*cxb30000*/
pattern7 v=msolid c=cx228B22;  /*couleur la plus foncée*/

/*Définition de la légende, emplacement et cadre*/

legend1 label=('Total Wins') 
        position=(bottom center) /*va placer la légende en bas qui sera centrée*/
        frame /*va ajouter un cadre autour de la légende*/
   		across=1;
/*pour la variable total_wins*/

proc gmap data=world_map_merged map=world_map_merged all;
   id id;
   choro total_wins / statistic=mean levels=7 legend=legend1;
run;
quit;
*ods pdf close;


*ods pdf file="/home/u63956311/SAS_PROJET/sorties_ods/map_total_losses.pdf";  
/*pour la variable total_losses*/
goptions reset=all;
title "Nombre total de défaites par pays";

pattern1 v=msolid c=cxfee8c8;  /*couleur la plus claire*/
pattern2 v=msolid c=cxfdbb84;
pattern3 v=msolid c=cxfc8d59;
pattern4 v=msolid c=cxef6548;
pattern5 v=msolid c=cxd7301f;
pattern6 v=msolid c=cxb30000; /*cxb30000*/
pattern7 v=msolid c=cx7f0000;  /*couleur la plus foncée*/

/*Définition de la légende, emplacement et cadre*/

legend1 label=('Total Losses') 
        position=(bottom center) /*va placer la légende en bas qui sera centrée*/
        frame /*va ajouter un cadre autour de la légende*/
        across=1;
proc gmap data=world_map_merged map=world_map_merged all;
   id id;
   choro total_losses / statistic=mean levels=7 legend=legend1;
run;
quit;
*ods pdf close;

*ods pdf file="/home/u63956311/SAS_PROJET/sorties_ods/map_ratio_win.pdf";  
/*pour la variable ratio_win*/
goptions reset=all;
title "Le taux de victoire (Win Ratio) par pays";

pattern1 v=msolid c=cxB22222;  /*couleur la plus claire*/
pattern2 v=msolid c=cxFF4500;
pattern3 v=msolid c=cxFFA500;
pattern4 v=msolid c=cxFFD700;
pattern5 v=msolid c=cxADFF2F;
pattern6 v=msolid c=cx32CD32; /*cxb30000*/
pattern7 v=msolid c=cx228B22;  /*couleur la plus foncée*/

/*Définition de la légende, emplacement et cadre*/

legend1 label=('Win Ratio') 
        position=(bottom center) /*va placer la légende en bas qui sera centrée*/
        frame/*va ajouter un cadre autour de la légende*/
        across=1;
proc gmap data=world_map_merged map=world_map_merged all;
   id id;
   choro ratio_win / statistic=mean levels=7 legend=legend1;
run;
quit;
*ods pdf close;


/****STATS SELON LE JOUEUR****/

proc sql;
    create table work.player_stats as
    select 
        player_ioc, 
        player_name, 
        min(player_rank) as min_rank, 
        max(player_rank_points) as max_rank_points,
        min(player_rank_points) as min_rank_points, 
        sum(case when is_winner = 1 then 1 else 0 end) as matches_won, 
        sum(case when is_winner = 0 then 1 else 0 end) as matches_lost, 
        calculated matches_won + calculated matches_lost as total_matches,
        calculated matches_won / calculated total_matches as ratio_win 
    from 
        work.new_matches
    group by 
        player_ioc, 
        player_name
    having
    	total_matches > 50;
quit;

/*  Dans cette partie, le but est de déterminer pour chaque joueur:
    - le nombre de matchs qu'il a gagnés,
    - le nombre de matchs qu'il a perdus,
    - le nombre total de matchs joués,
    - ainsi que le ratio de victoires,
    - sa nationalité,
    - enfin, filtrer les joueurs ayant plus de 100 matchs gagnés 
      pour avoir un ratio qui aurait du sens*/

/*proc sql;
    create table work.player_stats as
    select 
        player_ioc, 
        player_name, 
        min(player_rank) as player_rank,
        max(player_rank_points) as player_rank_points,
        sum(is_winner = 1) as matches_won, 
        sum(is_winner = 0) as matches_lost,
        calculated matches_won + calculated matches_lost as total_matches, 
        calculated matches_won / calculated total_matches as ratio_win
    from 
        work.new_matches
    group by 
        player_ioc, 
        player_name,
        player_rank,
        player_rank_points;
/*    having 
        player_rank is not null and 
        player_rank < 10 and
        total_matches > 50;
*/
*quit;

/* La table player_stats est modifiée pour ne conserver que les colonnes souhaitées. 
   Ensuite, en ajoutant le rang, elle est exportée pour inclusion dans le rapport.*/
proc sql;
    create table work.player_stats_2 as
    select 
        player_ioc, 
        player_name, 
        /*player_rank, 
        player_rank_points,*/
        matches_won, 
        matches_lost, 
        total_matches, 
        min_rank,
        round(ratio_win, 0.01) as ratio_win
    from work.player_stats
    order by ratio_win desc;
quit;

data work.player_stats_3;
    set work.player_stats_2;
    Rang = _N_; 
run;

*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/ratio_by_player.html";
proc print data=work.player_stats_3 (obs=20) label noobs;
    title "Classement des 20 meilleurs joueurs et joueuses selon le ratio de victoires depuis 1949";
    label player_ioc = 'Pays'
          player_name = 'Nom du joueur'
          matches_won = 'Nombre de victoires'
          matches_lost = 'Nombre de défaites'
          total_matches = 'Nombre de matchs'
          min_rank = 'Meilleur rang'
          ratio_win = 'Taux de victoires';
run;
*ods html close;

 /* nb de victoires :*/
proc sql;
    create table work.player_stats_2 as
    select 
        player_ioc, 
        player_name, 
        /*player_rank, 
        player_rank_points,*/
        matches_won, 
        /*matches_lost*/
        total_matches
        /*round(ratio_win, 0.01) as ratio_win*/
    from work.player_stats
    order by total_matches desc;
quit;

data work.player_stats_3;
    set work.player_stats_2;
    Rang = _N_; 
run;

*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/totmatches_by_player.html";
proc print data=work.player_stats_3 (obs=20) label noobs;
    title "Classement des 20 meilleurs joueurs et joueuses selon le total de matchs disputés";
    label player_ioc = 'Pays'
          player_name = 'Nom du joueur'
          matches_won = 'Nombre de victoires'
          total_matches = 'Nombre de matchs';
run;
*ods html close;

proc sql;
    create table work.player_stats_2 as
    select 
        player_ioc, 
        player_name, 
        /*player_rank, 
        player_rank_points,*/
        matches_won, 
        /*matches_lost*/
        total_matches
        /*round(ratio_win, 0.01) as ratio_win*/
    from work.player_stats
    order by matches_won desc;
quit;

data work.player_stats_3;
    set work.player_stats_2;
    Rang = _N_; 
run;

*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/totwins_by_player.html";
proc print data=work.player_stats_3 (obs=20) label noobs;
    title "Classement des 20 meilleurs joueurs et joueuses selon le nombre de victoires";
    label player_ioc = 'Pays'
          player_name = 'Nom du joueur'
          matches_won = 'Nombre de victoires'
          total_matches = 'Nombre de matchs';
run;
*ods html close;


/*  On veut filtrer notre table selon la date, rang, points*/

proc sql;
    create table sorted_matches as
    select tourney_level, tourney_date, player_name, 
    player_rank, player_rank_points, is_winner, league
    from work.new_matches
    order by tourney_date desc, player_rank asc, player_rank_points asc;
quit;

proc sql;
    create table top_player_per_date as
    select a.tourney_date,
           a.tourney_level,
           a.player_name,
           a.player_rank,
           a.player_rank_points,
           a.league
    from work.new_matches as a
    inner join (
        select tourney_date, min(player_rank) as max_rank
        from work.new_matches
        group by tourney_date
    ) as b
    on a.tourney_date = b.tourney_date and a.player_rank = b.max_rank
    order by a.tourney_date desc, a.player_rank asc, a.player_rank_points asc;
quit;

/*  Pour la date la plus récente dans nos bases, on a: 
	N. Djokovic: rang 1 en atp (tennis masculin)
	A. Barty: rang 1 en wta (tennis féminin)
	On va tracer 2 graphes: 
	1er => l'évolution du classement de ces deux joueurs au fil du temps
	2er => et leur evolution en terme de points de classement au fil du temps*/
	
proc sql;
    create table filtered_matches as
    select tourney_date, player_name, player_rank, player_rank_points, league
    from sorted_matches
    where player_name in ('Novak Djokovic', 'Ashleigh Barty')
    order by player_name, tourney_date;
quit;

*ods pdf file="/home/u63956311/SAS_PROJET/sorties_ods/djo_barty_rank.pdf";  
proc sgplot data=filtered_matches;
    series x=tourney_date y=player_rank / group=player_name 
        lineattrs=(pattern=solid) markers name="players";
    keylegend / title="Légende" location=inside position=BOTTOMRIGHT across=1;
    styleattrs datacontrastcolors=(violet lightblue);
    xaxis label="Date du tournoi" display=(nolabel);
    yaxis label="Classement des joueurs" reverse; 
    title "L'évolution du classement des joueurs au fil du temps";
run;
*ods pdf close;

*ods pdf file="/home/u63956311/SAS_PROJET/sorties_ods/djo_barty_rank_points.pdf";  
proc sgplot data=filtered_matches;
    series x=tourney_date y=player_rank_points / group=player_name 
        lineattrs=(pattern=solid) markers name="players";
    keylegend / title="Légende" location=inside position=topleft across=1;
    styleattrs datacontrastcolors=(violet lightblue);
    xaxis label="Date du tournoi";
    yaxis label="Classement des joueurs par Points"; 
    title "L'évolution des points de classement au fil du temps";
run;
*ods pdf close;

/*  Au niveau individuel (par joueur), 
	on va chercher les performances*/

/*
FAIT PLUS HAUT
proc sql;
    create table player_statistics as
    select 
        player_name,
        sum(is_winner = 1) as wins,
        sum(is_winner = 0) as losses,
        calculated wins + calculated losses as total,
        calculated wins / calculated total as ratio format=8.2,
        max(player_rank_points) as max_rank_points,
        min(player_rank) as max_rank
    from work.new_matches
    group by player_name
    order by player_name;
quit;

proc sql;
    create table player_statistics as
    select 
        player_name,
        sum(is_winner = 1) as wins,
        sum(is_winner = 0) as losses,
        calculated wins + calculated losses as total,
        case 
            when (calculated total > 0) then (calculated wins / calculated total)
            else 0
        end as ratio format=8.2,
        max(player_rank_points) as max_rank_points,
        min(player_rank) as max_rank
    from work.new_matches
    group by player_name
    having wins > 100
    order by ratio desc;
quit;

proc print data = player_statistics (obs = 10);
run;

proc sql;
    create table player_statistics_2 as
    select 
        player_name,
        league,
        sum(case when is_winner = 1 then 1 else 0 end) as wins,
        sum(case when is_winner = 0 then 1 else 0 end) as losses,
        calculated wins + calculated losses as total,
        case 
            when calculated total > 0 then calculated wins / calculated total
            else 0
        end as ratio format=8.2,
        max(player_rank_points) as max_rank_points,
        min(player_rank) as max_rank
    from work.new_matches
    where tourney_date >= '01JAN1990'd 
    group by player_name, league
    having wins > 50
    order by ratio desc;
quit;

proc print data=player_statistics_2(obs=10);
run;

*/

/*  Prenons la table matches pour: 
	- créer une nouvelle colonne 'gender' qui prendra:
	'male' si league = wta
	'female si league = ata*/

data matches_with_gender;
    set work.new_matches;
    if league = 'wta' then gender = 'female';
    else if league = 'atp' then gender = 'male';
run;

/*  Merge des deux tables pour récupérer birthdate : 
	clé: player_ID et gender*/
 
proc sql;
    create table matches_players_merged as
    select 
        a.*, 
        b.birthdate
    from matches_with_gender as a
    inner join work.players as b
    on a.player_id = b.player_id and a.gender = b.gender;
quit;

data matches_players_merged_new;
    set matches_players_merged;
    format birthdate yymmdd10.;
run;

data matches_players_new;
    set matches_players_merged;
    birthdate = input(put(birthdate, 8.), yymmdd8.);
    format birthdate yymmdd10.;
run;

proc print data=matches_players_new(obs=10);
run;

/*  récupérer tout ceux qui ont été classé 1er
	faire une analyse pour trouver le temps moyen (et max, min) mis
	pour devenir 1er*/

data perform_joueurs;
	set work.matches_players_new;
	keep tourney_date 
		 player_ioc
		 league
		 player_id
		 player_name
		 player_rank
		 gender
		 birthdate;
run;

proc sql;
    create table perform_joueurs_sorted as
    select *
    from perform_joueurs
    where tourney_date is not null 
      and player_ioc is not null 
      and league is not null 
      and player_id is not null
      and player_name is not null
      and player_rank is not null
      and gender is not null
      and birthdate is not null
    order by player_name, 
             tourney_date, 
             player_rank;
quit;

/*  les joueurs qui ont atteint au moins une fois le rang 1 (player_rank=1)*/

proc sql;
    create table players_with_rank_1 as
    select distinct player_id, player_name
    from perform_joueurs_sorted
    where player_rank = 1;
quit;

/*il y en a 50

On vient filtrer maintenant la table uniquement pour ces joueurs
*/

proc sql;
    create table unique_players_with_rank_1 as
    select a.*
    from perform_joueurs_sorted as a
    inner join players_with_rank_1 as b
    on a.player_id = b.player_id;
quit;

/*temps qui a été mis avant d'être classé 1er
  second filtre pour ne garder que les joueurs "récents"*/

proc sql;
    create table time_to_rank_1 as
    select player_name,
           player_ioc,
    	   league,
           birthdate format=DATE9.,
           player_id, 
           min(tourney_date) as first_date format=DATE9., 
           min(case when player_rank = 1 then tourney_date else . end) as rank_1_date format=DATE9., 
           intck('day', 
                 min(tourney_date), 
                 min(case when player_rank = 1 then tourney_date else . end)) as days_to_rank_1
    from 
           unique_players_with_rank_1
    where 
           birthdate > '01JAN1960'd 
    group by 
           player_id, player_name, league, birthdate, player_ioc
    order by
    	   days_to_rank_1;
quit;

/*export : */

data work.time_to_rank_2;
    set work.time_to_rank_1;
    birthdate_ = catx(' ', put(day(birthdate), 2.), 
                                         upcase(put(birthdate, monname3.)), 
                                         put(year(birthdate), 4.));
    first_date_ = catx(' ', put(day(first_date), 2.), 
                                          upcase(put(first_date, monname3.)), 
                                          put(year(first_date), 4.));
    rank_1_date_ = catx(' ', put(day(rank_1_date), 2.), 
                                           upcase(put(rank_1_date, monname3.)), 
                                           put(year(rank_1_date), 4.));
    drop birthdate first_date rank_1_date;
    rename birthdate_ = birthdate
           first_date_ = first_date
           rank_1_date_ = rank_1_date;

    annees = floor(days_to_rank_1 / 365.25);
    mois = floor(mod(days_to_rank_1, 365.25) / 30.44);

    if mois = 0 then
        annees_mois = catx(' ', annees, 'ans');
    else
        annees_mois = catx(' ', annees, 'ans et', mois, 'mois');

    Rang = _N_; 
    drop player_id annees mois days_to_rank_1;
run;

*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/time_to_first.html";
proc print data=work.time_to_rank_2 (obs=20) label noobs;
    title "Top 20 des durées pour atteindre la première place du classement WTA ou ATP";
    label birthdate = 'Date de naissance'
          player_name = 'Nom'
          player_ioc = 'Pays'
          league = 'Tournoi'
          first_date = 'Premier match professionnel'
          rank_1_date = 'Classé numéro 1'
          annees_mois = 'Temps pour devenir 1er';
run;
*ods html close;

/* classement par âge - rank 1 :*/
proc sql;
    create table time_to_rank_2_since_birth as
    select player_name,
    	   player_ioc,
           league,
           birthdate format=DATE9.,
           player_id, 
           min(tourney_date) as first_date format=DATE9., 
           min(case when player_rank = 1 then tourney_date else . end) as rank_1_date format=DATE9., 
           intck('day', birthdate, 
                 min(case when player_rank = 1 then tourney_date else . end)) as days_from_birth_to_rank_1 
    from 
           unique_players_with_rank_1
    where 
           birthdate > '01JAN1960'd 
    group by 
           player_id, player_name, league, birthdate, player_ioc
    order by
           days_from_birth_to_rank_1;
quit;

data work.time_to_rank_2_since_birth_2;
    set work.time_to_rank_2_since_birth;
    birthdate_ = catx(' ', put(day(birthdate), 2.), 
                                         upcase(put(birthdate, monname3.)), 
                                         put(year(birthdate), 4.));
    first_date_ = catx(' ', put(day(first_date), 2.), 
                                          upcase(put(first_date, monname3.)), 
                                          put(year(first_date), 4.));
    rank_1_date_ = catx(' ', put(day(rank_1_date), 2.), 
                                           upcase(put(rank_1_date, monname3.)), 
                                           put(year(rank_1_date), 4.));
    drop birthdate first_date rank_1_date;
    rename birthdate_ = birthdate
           first_date_ = first_date
           rank_1_date_ = rank_1_date;

    annees = floor(days_from_birth_to_rank_1 / 365.25);
    mois = floor(mod(days_from_birth_to_rank_1, 365.25) / 30.44);

    if mois = 0 then
        annees_mois = catx(' ', annees, 'ans');
    else
        annees_mois = catx(' ', annees, 'ans et', mois, 'mois');

    Rang = _N_; 
    drop player_id annees mois days_from_birth_to_rank_1;
run; 

*ods html file="/home/u63956311/SAS_PROJET/sorties_ods/time_to_first_since_birth.html";
proc print data=work.time_to_rank_2_since_birth_2 (obs=20) label noobs;
    title "Top 20 des plus jeunes joueurs et joueuses de l'histoire du tennis";
    label birthdate = 'Date de naissance'
          player_name = 'Nom'
          player_ioc = 'Pays'
          league = 'Tournoi'
          first_date = 'Premier match professionnel'
          rank_1_date = 'Classé numéro 1'
          annees_mois = 'Âge';
run;
*ods html close;

/*vérif:*/

/*proc sql;
	select *
	from unique_players_with_rank_1
	where player_name = "Serena Williams";
*quit;

/* MACRO FINALE : stats pour un player saisi :*/
 
%macro plot_player_rank(first_name=, last_name=);
    proc sql;
        create table player_rank_data as
        select *
        from perform_joueurs_sorted
        where upcase(scan(player_name, 1, ' ')) = "%upcase(&first_name)"
          and upcase(scan(player_name, 2, ' ')) = "%upcase(&last_name)"
        order by tourney_date;
    quit;

    %if %sysfunc(exist(player_rank_data)) %then %do;
        proc sgplot data=player_rank_data;
            series x=tourney_date y=player_rank / markers lineattrs=(pattern=solid);
            xaxis label="Tournament Date" type=time interval=month valuesformat=year4.;
            yaxis label="Player Rank" reverse; 
            title "Evolution of Player Rank: &first_name &last_name";
        run;
    %end;
    %else %do;
        %put NOTE: No data found for the player &first_name &last_name.;
    %end;
%mend plot_player_rank;

%plot_player_rank(first_name=Novak, last_name=Djokovic);
%plot_player_rank(first_name=Maria, last_name=Sharapova);
%plot_player_rank(first_name=Rafael, last_name=Nadal);