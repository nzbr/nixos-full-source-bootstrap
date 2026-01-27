= Abstract

// about 1/2 page:
// + Motivation(Why do we care?)
// + Problem statement (What problem are we trying to solve?)
// + Approach (How did we go about it?)
// + Results (What's the answer?)
// + Conclusion (What are the implications of the answer?)

Even when compiled from source, executables are at most as trustworthy as the compiler that produced them.
Considering that the compilers commonly used to build Linux-based operating systems are usually compiled with existing binary versions of themselves, their trustworthiness can not be guaranteed.
The process of building a compiler with a different compiler, thus breaking the loop, is called "bootstrapping".

In this thesis, we present our implementation of a full-source bootstrap for the NixOS Linux distribution.
We build a Linux environment with the Nix package manager from a minimal, hand-auditable binary seed, and then use it to install NixOS.
For this, we use a version of Nixpkgs---the package set on which NixOS is based---that we also modified to be bootstrapped from a hand-auditable binary seed.
Although there are compilers in Nixpkgs that we can not build from the bootstrap seed yet, the result is a NixOS installation, most parts of which are fully compiled from source.
Finally, we discuss the practicality of the full-source bootstrap and how it can be improved upon so that every NixOS user can benefit from the advances in trustworthiness we have achieved.

= Kurzfassung

// Gleicher Text auf Deutsch
#text(
  lang: "de",
  [
    Selbst wenn sie aus Quelltext kompiliert wurden, können ausführbare Programmdateien maximal so vertrauenswürdig sein wie der Compiler, durch den sie erzeugt wurden.
    Die Compiler, die zum Übersetzen Linux-basierter Betriebssysteme üblicherweise verwendet werden, werden für gewöhnlich mittels einer existierenden Kopie ihrer selbst kompiliert.
    Aufgrund der Tatsache, dass diese als ausführbare Dateien vorliegen, kann ihre Vertrauenswürdigkeit nicht garantiert werden.
    Der Vorgang, einen solchen selbstübersetzenden Compiler mit Hilfe eines anderen Compilers zu bauen, um diesen Kreis zu durchbrechen, wird als "Bootstrapping" bezeichnet.

    In dieser Arbeit präsentieren wir unsere Umsetzung eines vollständigen Bootstraps für die Linux-distribution NixOS.
    Wir bauen eine Linux-Umgebung mit dem Paketverwaltungsprogramm Nix aus einer minimalen, menschenüberprüfbaren Ausgangsbinärdatei und benutzen diese, um NixOS zu installieren.
    Zu diesem Zweck verwenden wir eine modifizierte Version von Nixpkgs---dem Paketsatz, auf dem NixOS basiert---welche ebenfalls aus einer menschenüberprüfbaren Ausgangsbinärdatei erzeugt wird.
    Ungeachtet der Tatsache, dass Nixpkgs Compiler enthält, welche wir noch nicht aus der Ausgangsbinärdatei erzeugen können, ist das Resultat eine NixOS-Installation, die, zum überwiegenden Teil, vollständig aus Quelltext erzeugt wurde.
    Schließlich erörtern wir die Zweckmäßigkeit des vollständigen Bootstraps und wie dieser verbessert werden kann, sodass alle Anwender\*innen von NixOS von den Fortschritten in Sachen Vertrauenswürdigkeit, die wir erreicht haben, profitieren können.
  ],
)
