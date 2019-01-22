# SID - TP Spark

# Objectifs du TP

Le but de ce TP est d'apprendre à utiliser les technologies Hadoop et Spark afin de pouvoir lancer un programme de façon distribuée sur un cluster de machines.

Hadoop est un framework libre et open-source qui a pour but de faciliter la création d'applications distribuées au niveau du stockage et du traitement des données.

Apache Spark est un framework libre et open-source qui fournit des un bons nombres d'outils utiles pour la programmation distribuée. Initialement prévu pour fonctionner avec le langage de programmation Scala, nous avons décidé d'utiliser le langage Python, avec lequel nous avons plus d'expérience.

En guise d'exemple, nous allons analyser les données trouvées sur le site [opendata.lillemetropole.fr](https://opendata.lillemetropole.fr/explore/dataset/naissances-par-commune-departement-et-region-de-2003-a-2013/table/). Notre objectif sera de trouver le nombre de naissances par commune grâce au modèle MapReduce.

Vous pouvez consulter notre répertoire GitHub [ici](https://github.com/HugoAlder/spark).

## Utilisation de Spark en local

Nous avons commencé par installer PySpark (Spark pour Python) sur une seule machine.

Nous utilisons des RDD afin de parcourir notre fichier CSV et obtenir les informations voulues grâce à une opération de Map/Reduce.

Pour le Map, nous séparons les champs par ";" tout en passant le header, puis nous ne sélectionnons que ceux qui nous intéressent, à savoir _Libellé Gréographique_ et _Naissances._ Le résultat est stocké dans une RDD.

Pour le Reduce, nous recoupons les données par la clef _Libellé Géographique_, puis nous ajoutons toutes les valeurs associées à une même clef pour obtenir enfin le nombre de naissances par commune.

## Installation du cluster

Pour la suite de ce projet, nous avons créé 4 machines sur l'OpenStack de l'université afin de pouvoir créer une cluster.

### HDFS

Il a fallut commencer par installer le Hadoop File System, la partie d'Hadoop qui s'occupe du stockage des données.

### YARN

### Spark

