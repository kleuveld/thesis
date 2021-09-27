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

        # LaTeXTools has run pdflatex and returned control to the builder
        # here we just add text saying the step is done, to give some feedback
        self.display("done.\n")

        # now run bibtex
        chapters =   ["chapters/cameroon_trust/cameroontrust_paper.aux",
                     "chapters/conclusion/conclusion.aux",
                     "chapters/congogbv/congogbv.aux",
                     "chapters/introduction/introduction.aux",
                     "chapters/n2a_impact/n2a_impact.aux",
                     "chapters/slfootball/slfootball.aux"]
        self.display("Running bibtex...\n")
        for file in chapters:
            yield(BIBTEX + [file.rstrip(".aux")],"  (%s)\n" % file)
            self.display("done.\n")


        # second run of pdflatex
        yield(
            PDFLATEX + [self.base_name],
            "Running pdflatex again..."
        )

        self.display("done!\n")

        # third run of pdflatex
        yield(
            PDFLATEX + [self.base_name],
            "Running pdflatex for the last time..."
        )

        self.display("done.\n")