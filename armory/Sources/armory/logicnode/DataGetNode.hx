package armory.logicnode;

class DataGetNode extends LogicNode {

    var values:Array<Dynamic>;
    var found:Array<Bool>;

    public function new(tree:LogicTree) {
        super(tree);
    }

    override function run(from:Int):Void {
        var data:Dynamic = inputs[1].get();
        var keyCount = inputs.length - 2;

        values = [];
        found = [];

        for (i in 0...keyCount) {
            var key:String = inputs[i + 2].get();
            var exists = data != null && key != null && Reflect.hasField(data, key);

            found.push(exists);
            values.push(exists ? Reflect.field(data, key) : null);
        }

        runOutput(0);

        for (i in 0...keyCount) {
            if (found[i]) {
                runOutput(i * 2 + 1);
            }
        }
    }

    override function get(from:Int):Dynamic {
        return values[Std.int((from - 2) / 2)];
    }
}