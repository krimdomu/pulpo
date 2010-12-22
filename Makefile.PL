use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Pulpo',
   VERSION_FROM => 'lib/Pulpo.pm',
   PREREQ_PM => {'Net::Server::PreFork' => '0'},
   EXE_FILES => ['bin/pulpo'],
   LICENSE => 'perl'
);

