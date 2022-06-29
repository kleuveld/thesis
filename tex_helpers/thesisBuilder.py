from pdfBuilder import PdfBuilder
import os

# here we define the commands to be used
# commands are passed to subprocess.Popen which prefers a list of
# arguments to a string
PDFLATEX = ["pdflatex", "-interaction=nonstopmode", "-synctex=1"]
BIBTEX = ["bibtex"]

class thesisBuilder(PdfBuilder):
    def __init__(self, *args):
        super(thesisBuilder, self).__init__(*args)

        # now we do the initialization for this builder
        self.name = "thesisBuilder"

    def commands(self):
        self.display("\n\nthesisBuilder: ")

        # first run of pdflatex
        # this tells LaTeXTools to run:
        #  pdflatex -interaction=nonstopmode -synctex=1 tex_root
        # note that we append the base_name of the file to the command here
        yield(PDFLATEX + [self.base_name], "Running pdflatex...")
        #yield(PDFLATEX + [thesis.tex], "Running pdflatex...")
        
        # LaTeXTools has run pdflatex and returned control to the builder
        # here we just add text saying the step is done, to give some feedback
        self.display("done.\n")

        # now run bibtex
        chapters =   ["chapters/cameroontrust/cameroontrust_paper",
                     "chapters/conclusion/conclusion",
                     "chapters/congogbv/congogbv",
                     "chapters/introduction/introduction",
                     "chapters/n2a_impact/n2a_impact",
                     "chapters/slfootball/slfootball",
                     "chapters/acknowledgements/acknowledgements",
                     "chapters/summary_dutch/summary_dutch",
                     "chapters/summary_english/summary_english"
                     ]
        self.display("Running bibtex...\n")
        for file in chapters:
            yield(BIBTEX + [file],"  (%s)\n" % file)
            self.display("done.\n")


        # second run of pdflatex
        yield(
            PDFLATEX + [self.base_name],
            #PDFLATEX + [thesis.tex],
            "Running pdflatex again..."
        )

        self.display("done!\n")

        # third run of pdflatex
        yield(
            PDFLATEX + [self.base_name],
            #PDFLATEX + [self.base_name]
            "Running pdflatex for the last time..."
        )

        self.display("done.\n")