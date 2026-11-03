
package armory.logicnode;

class DataSetNode extends LogicNode {

    var data:Dynamic;

    public function new(tree:LogicTree) {
        super(tree);
    }

    override function run(from:Int):Void {
        data = {};

        var i = 1;

        while (i < inputs.length) {
            var key:String = inputs[i].get();
            var value:Dynamic = inputs[i + 1].get();

            if (key != null && key != "") {
                Reflect.setField(data, key, value);
            }

            i += 2;
        }

        runOutput(0);
    }

    override function get(from:Int):Dynamic {
        return data;
    }
}
