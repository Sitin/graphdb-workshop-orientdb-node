// Generated on 2014-06-20 using generator-nodejs 2.0.0
module.exports = function (grunt) {
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        clean: ['lib/'],
        coffeelint: {
            options: {
                configFile: 'coffeelint.json'
            },
            app: ['coffee/**/*.coffee'],
            tests: ['test/**/*.coffee']
        },
        coffee: {
            app: {
                expand: true,
                options: {
                    sourceMap: true
                },
                cwd: 'coffee/',
                src: ['**/*.coffee'],
                dest: 'lib/',
                ext: '.js'
            },
            tests: {
                expand: true,
                cwd: 'test/',
                src: ['**/*.coffee'],
                dest: 'test/',
                ext: '.js'
            }
        },
        complexity: {
            generic: {
                src: ['lib/**/*.js'],
                options: {
                    errorsOnly: false,
                    cyclometric: 6,       // default is 3
                    halstead: 16,         // default is 8
                    maintainability: 100  // default is 100
                }
            }
        },
        jshint: {
            all: [
                'Gruntfile.js',
                'index.js'
            ],
            options: {
                jshintrc: '.jshintrc'
            }
        },
        mochacli: {
            all: ['test/**/*.js'],
            options: {
                reporter: 'spec',
                ui: 'tdd'
            }
        },
        watch: {
            js: {
                files: ['**/*.js', '!node_modules/**/*.js'],
                tasks: ['default'],
                options: {
                    nospawn: true
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-complexity');
    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-mocha-cli');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-coffeelint');
    grunt.loadNpmTasks('grunt-contrib-clean');

    grunt.registerTask('compile', ['coffeelint', 'coffee']);
    grunt.registerTask('test', ['compile', 'complexity', 'jshint', 'mochacli', 'watch']);
    grunt.registerTask('ci', ['compile', 'complexity', 'jshint', 'mochacli']);
    grunt.registerTask('default', ['test']);
};
