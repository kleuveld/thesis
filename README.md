# Introduction

This folder contains the files for the dissertation of Koen Leuveld.


# Building LaTeX

The file thesis.tex contains references to all the individual chapters. I build the file using the LaTeXTools package of SublimeText 3. The file should be built using ThesisBuilder.py, placed in sublimetext packages folder, in the subfolder User/LaTeXTools-Builders. ThesisBuilder is then included in the thesis.sublime-project file. A copy of ThesisBuilder.py is included in the tex_helpers folder. More info can be found: https://stmorse.github.io/journal/Thesis-writeup.html 

Paths are defined in thesis_paths.tex, which should not be included in git, so it can be different on each machine. Here's a template:

```
%general paths
\newcommand{\git}{C:/Users/kld330/git}
\newcommand{\dropbox}{C:/Users/kld330/Dropbox/}
\newcommand{\onedrive}{C:/Users/Koen/OneDriveWUR}
\newcommand{\encrypteddata}{D:/PhD/Papers}



\newcommand{\bibtex}{C:/Users/kld330/surfdrive2/Data/BibTeX}



%by paper

%slfootball
\newcommand{\slfootballTables}{\git/thesis/chapters/slfootball/Analysis/Tables}
\newcommand{\slfootballFigures}{\git/thesis/chapters/slfootball/Analysis/Figures}


%cameroontrust
\newcommand{\cameroontrustTables}{\encrypteddata/CameroonTrust/Tables}
\newcommand{\cameroontrustFigures}{\encrypteddata/CameroonTrust/Figures}


%CongoGBV
\newcommand{\congogbvTables}{\encrypteddata/CongoGBV/Tables}
\newcommand{\congogbvFigures}{\encrypteddata/CongoGBV/Figures}

```

# Running the Analysis

All stata files are run from their respective git repos, and not included here (yet).
