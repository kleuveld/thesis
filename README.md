# Introduction

This folder contains the files for the PhD thesis of Koen Leuveld. Respondents have not consented to sharing their data, so data is stored separately, and will be archived on publication of the thesis.


# Building LaTeX

The file thesis.tex contains references to all the individual chapters. Each chapter contains its own bibliography, through the use of the [chapterbib](https://www.ctan.org/pkg/chapterbib) package. To properly build the pdf, run pdflatex on the main file, then run biblatex on each chapter, and then run pdflatex twice.

I build the file using the LaTeXTools package of Sublime Text 3. The file ThesisBuilder.py (a copy of which is included in the tex_helpers folder) implements the build instructions outlined above. More info on how to set up Sublime Text 3 to use the builder can be found [here](https://stmorse.github.io/journal/Thesis-writeup.html). 

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
