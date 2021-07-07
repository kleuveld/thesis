This folder contains the files for the dissertation of Koen Leuveld.

Tex:
The file thesis.tex contains references to all the individual chapters. The file should be built using ThesisBuilder.py, placed in sublimetext packages folder, in the subfolder User/LaTeXTools-Builders. ThesisBuilder is then included in the thesis.sublime-project file. A copy of ThesisBuilder.py is included in the tex_helpers folder. More info can be found: https://stmorse.github.io/journal/Thesis-writeup.html 

Paths are defined in thesis_paths.tex, which should not be included in git, so it can be different on each machine. Here's a template:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcommand{\git}{C:/Users/Koen/Documents/GitHub}
\newcommand{\dropbox}{C:/Users/Koen/Dropbox}
\newcommand{\onedrive}{C:/Users/Koen/OneDriveWUR}


%by paper

%slfootball
\newcommand{\slfootballTables}{\git/thesis/chapters/slfootball/Analysis/Tables}
\newcommand{\slfootballFigures}{\git/thesis/chapters/slfootball/Analysis/Figures}


%mklink /D "C:\Users\Koen\OneDriveWUR" "C:\Users\Koen\OneDrive - WageningenUR"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Chapter text, figures and tables are copied from their respective git repos.

Stata:
All stata files are run from their respective git repos, and not included here (yet).
