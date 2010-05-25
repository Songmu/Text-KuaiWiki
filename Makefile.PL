use inc::Module::Install;
name 'Text-KuaiWiki';
all_from 'lib/Text/KuaiWiki.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
