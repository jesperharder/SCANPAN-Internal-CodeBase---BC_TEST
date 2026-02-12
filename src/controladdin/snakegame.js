/// 2026.02             Jesper Harder       104         Snake Game, Added control add-in page and client assets (AL, JS, CSS)
(function () {
    'use strict';

    var gridSize = 20;
    var tileCount = 20;
    var tickMs = 120;
    var game = null;
    var demoMode = false;

    function invoke(name, args) {
        if (window.Microsoft && Microsoft.Dynamics && Microsoft.Dynamics.NAV) {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []);
        }
    }

    function randomCell() {
        return {
            x: Math.floor(Math.random() * tileCount),
            y: Math.floor(Math.random() * tileCount)
        };
    }

    function sameCell(a, b) {
        return a.x === b.x && a.y === b.y;
    }

    function createLayout() {
        document.body.innerHTML = '';

        var wrapper = document.createElement('div');
        wrapper.className = 'snake-wrapper';

        var header = document.createElement('div');
        header.className = 'snake-header';
        header.innerHTML = '<div class="snake-title">SCANPAN Snake</div><div class="snake-score" id="snake-score">Score: 0</div>';

        var instructions = document.createElement('div');
        instructions.className = 'snake-instructions';
        instructions.textContent = 'Use Arrow keys or WASD. Press Space to restart. Demo Mode plays automatically.';

        var canvas = document.createElement('canvas');
        canvas.width = gridSize * tileCount;
        canvas.height = gridSize * tileCount;
        canvas.id = 'snake-canvas';

        var overlay = document.createElement('div');
        overlay.className = 'snake-overlay hidden';
        overlay.id = 'snake-overlay';

        var actions = document.createElement('div');
        actions.className = 'snake-actions';

        var restartButton = document.createElement('button');
        restartButton.className = 'snake-button snake-restart';
        restartButton.type = 'button';
        restartButton.textContent = 'New Game';
        restartButton.addEventListener('click', function () {
            StartNewGame();
        });

        var demoButton = document.createElement('button');
        demoButton.className = 'snake-button snake-demo';
        demoButton.type = 'button';
        demoButton.textContent = 'Demo Mode';

        var stopDemoButton = document.createElement('button');
        stopDemoButton.className = 'snake-button snake-stop-demo';
        stopDemoButton.type = 'button';
        stopDemoButton.textContent = 'Stop Demo';
        stopDemoButton.disabled = true;

        actions.appendChild(restartButton);
        actions.appendChild(demoButton);
        actions.appendChild(stopDemoButton);

        wrapper.appendChild(header);
        wrapper.appendChild(instructions);
        wrapper.appendChild(canvas);
        wrapper.appendChild(overlay);
        wrapper.appendChild(actions);
        document.body.appendChild(wrapper);

        return {
            canvas: canvas,
            overlay: overlay,
            score: document.getElementById('snake-score'),
            demoButton: demoButton,
            stopDemoButton: stopDemoButton
        };
    }

    function start() {
        var ui = createLayout();
        var ctx = ui.canvas.getContext('2d');

        function setDemoMode(isEnabled) {
            demoMode = isEnabled;
            ui.demoButton.disabled = demoMode;
            ui.stopDemoButton.disabled = !demoMode;
        }

        function reset() {
            game = {
                snake: [{ x: 10, y: 10 }],
                direction: { x: 1, y: 0 },
                nextDirection: { x: 1, y: 0 },
                food: randomCell(),
                score: 0,
                over: false
            };

            while (sameCell(game.food, game.snake[0])) {
                game.food = randomCell();
            }

            ui.overlay.classList.add('hidden');
            ui.overlay.textContent = '';
            ui.score.textContent = 'Score: 0';
            invoke('ScoreChanged', [0]);
        }

        function canMoveTo(nextCell) {
            var eatFood = sameCell(nextCell, game.food);
            var collisionLimit = game.snake.length - (eatFood ? 0 : 1);
            var i;

            if (nextCell.x < 0 || nextCell.y < 0 || nextCell.x >= tileCount || nextCell.y >= tileCount) {
                return false;
            }

            for (i = 0; i < collisionLimit; i += 1) {
                if (sameCell(nextCell, game.snake[i])) {
                    return false;
                }
            }

            return true;
        }

        function chooseDemoDirection() {
            var head = game.snake[0];
            var food = game.food;
            var horizontal = food.x >= head.x ? 1 : -1;
            var vertical = food.y >= head.y ? 1 : -1;
            var preferredMoves = [
                { x: horizontal, y: 0 },
                { x: 0, y: vertical },
                { x: -horizontal, y: 0 },
                { x: 0, y: -vertical }
            ];
            var i;
            var nextCell;

            for (i = 0; i < preferredMoves.length; i += 1) {
                nextCell = {
                    x: head.x + preferredMoves[i].x,
                    y: head.y + preferredMoves[i].y
                };

                if (canMoveTo(nextCell)) {
                    game.nextDirection = preferredMoves[i];
                    return;
                }
            }
        }

        function spawnFood() {
            var next = randomCell();
            var blocked = true;

            while (blocked) {
                blocked = false;
                for (var i = 0; i < game.snake.length; i += 1) {
                    if (sameCell(next, game.snake[i])) {
                        blocked = true;
                        next = randomCell();
                        break;
                    }
                }
            }

            game.food = next;
        }

        function step() {
            if (!game || game.over) {
                return;
            }

            game.direction = game.nextDirection;
            var head = game.snake[0];
            var newHead = {
                x: head.x + game.direction.x,
                y: head.y + game.direction.y
            };

            if (newHead.x < 0 || newHead.y < 0 || newHead.x >= tileCount || newHead.y >= tileCount) {
                endGame();
                return;
            }

            for (var i = 0; i < game.snake.length; i += 1) {
                if (sameCell(newHead, game.snake[i])) {
                    endGame();
                    return;
                }
            }

            game.snake.unshift(newHead);

            if (sameCell(newHead, game.food)) {
                game.score += 1;
                ui.score.textContent = 'Score: ' + game.score;
                invoke('ScoreChanged', [game.score]);
                spawnFood();
            } else {
                game.snake.pop();
            }
        }

        function endGame() {
            game.over = true;
            setDemoMode(false);
            ui.overlay.classList.remove('hidden');
            ui.overlay.textContent = 'Game Over. Press Space or New Game.';
            invoke('GameOver', [game.score]);
        }

        function drawCell(cell, color) {
            ctx.fillStyle = color;
            ctx.fillRect(cell.x * gridSize, cell.y * gridSize, gridSize - 1, gridSize - 1);
        }

        function draw() {
            if (!game) {
                return;
            }

            ctx.fillStyle = '#111827';
            ctx.fillRect(0, 0, ui.canvas.width, ui.canvas.height);

            drawCell(game.food, '#f97316');
            for (var i = 0; i < game.snake.length; i += 1) {
                drawCell(game.snake[i], i === 0 ? '#16a34a' : '#22c55e');
            }
        }

        function gameLoop() {
            if (game && !game.over && demoMode) {
                chooseDemoDirection();
            }

            step();
            draw();
        }

        function startDemoMode() {
            if (!game || game.over) {
                reset();
                draw();
            }

            setDemoMode(true);
        }

        function stopDemoMode() {
            setDemoMode(false);
        }

        ui.demoButton.addEventListener('click', function () {
            startDemoMode();
        });

        ui.stopDemoButton.addEventListener('click', function () {
            stopDemoMode();
        });

        document.addEventListener('keydown', function (e) {
            if (!game) {
                return;
            }

            if (e.key === ' ' || e.code === 'Space') {
                StartNewGame();
                return;
            }

            if (demoMode) {
                return;
            }

            var next = game.nextDirection;

            if ((e.key === 'ArrowUp' || e.key === 'w' || e.key === 'W') && game.direction.y !== 1) {
                next = { x: 0, y: -1 };
            }

            if ((e.key === 'ArrowDown' || e.key === 's' || e.key === 'S') && game.direction.y !== -1) {
                next = { x: 0, y: 1 };
            }

            if ((e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') && game.direction.x !== 1) {
                next = { x: -1, y: 0 };
            }

            if ((e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') && game.direction.x !== -1) {
                next = { x: 1, y: 0 };
            }

            game.nextDirection = next;
        });

        reset();
        setDemoMode(false);
        draw();
        window.setInterval(gameLoop, tickMs);

        window.StartNewGame = function () {
            reset();
            draw();
        };

        invoke('ControlReady', []);
    }

    start();
}());
